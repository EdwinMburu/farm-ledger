import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FarmLedgerApp());
}

class FarmLedgerApp extends StatefulWidget {
  const FarmLedgerApp({super.key});

  @override
  State<FarmLedgerApp> createState() => _FarmLedgerAppState();
}

class _FarmLedgerAppState extends State<FarmLedgerApp> {
  bool loggedIn = false;
  int tab = 0;
  int nextCowId = 1;
  final tabHistory = <int>[0];
  String farmer = '';
  final cows = <Cow>[];
  final feeds = <FeedEntry>[];
  final production = <ProductionEntry>[];
  final expenses = <ExpenseEntry>[];
  final milkPrices = <MilkPriceEntry>[];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farm Ledger',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2d6a4f)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: loggedIn
          ? _home()
          : LoginScreen(
              onLogin: (name) async {
                await _loadCattle();
                await _loadFeeds();
                await _loadMilkPrices();
                await _loadProduction();
                await _loadExpenses();
                setState(() {
                  farmer = name;
                  loggedIn = true;
                  tab = 0;
                  tabHistory
                    ..clear()
                    ..add(0);
                });
              },
            ),
    );
  }

  void _openTab(int index) {
    if (index == tab) return;
    setState(() {
      tab = index;
      tabHistory.add(index);
    });
  }

  void _goBack() {
    if (tabHistory.length <= 1) return;
    setState(() {
      tabHistory.removeLast();
      tab = tabHistory.last;
    });
  }

  void _logout() {
    setState(() {
      loggedIn = false;
      tab = 0;
      tabHistory
        ..clear()
        ..add(0);
    });
  }

  void _assignMissingCowIds() {
    for (final cow in cows) {
      if (cow.id == 0) cow.id = nextCowId++;
    }
  }

  Future<void> _loadExpenses() async {
    final firestore = FirestoreService();

    try {
      final data = await firestore.loadExpenses();

      expenses.clear();

      for (final item in data) {
        final cowId = (item['cowId'] as num?)?.toInt();

        if (cowId == null) {
          continue;
        }

        Cow? matchingCow;

        for (final cow in cows) {
          if (cow.id == cowId) {
            matchingCow = cow;
            break;
          }
        }

        if (matchingCow != null) {
          expenses.add(
            ExpenseEntry(
              matchingCow,
              item['date'] ?? '',
              item['description'] ?? '',
              (item['amount'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Could not load expenses: $e');
    }
  }

  Future<void> _loadProduction() async {
    final firestore = FirestoreService();

    try {
      final data = await firestore.loadProduction();

      production.clear();

      for (final item in data) {
        final cowId = (item['cowId'] as num?)?.toInt();

        if (cowId == null) {
          continue;
        }

        Cow? matchingCow;

        for (final cow in cows) {
          if (cow.id == cowId) {
            matchingCow = cow;
            break;
          }
        }

        if (matchingCow != null) {
          production.add(
            ProductionEntry(
              matchingCow,
              item['date'] ?? '',
              (item['liters'] as num?)?.toDouble() ?? 0,
              (item['unitValue'] as num?)?.toDouble() ?? 0,
              documentId: item['_documentId'],
              session: item['session'] ?? 'morning',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Could not load production: $e');
    }
  }

  Future<void> _loadFeeds() async {
    final firestore = FirestoreService();

    try {
      final data = await firestore.loadFeeds();

      feeds.clear();

      for (final item in data) {
        feeds.add(
          FeedEntry(
            item['month'] ?? '',
            (item['cost'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Could not load feeds: $e');
    }
  }

  Future<void> _loadMilkPrices() async {
    final firestore = FirestoreService();

    try {
      final data = await firestore.loadMilkPrices();

      milkPrices
        ..clear()
        ..addAll(
          data.map(
            (item) => MilkPriceEntry(
              item['monthKey'] ?? '${item['month']}/${item['year']}',
              (item['unitValue'] as num?)?.toDouble() ?? 0,
            ),
          ),
        );
    } catch (e) {
      debugPrint('Could not load milk prices: $e');
    }
  }

  Future<void> _loadCattle() async {
    final firestore = FirestoreService();

    try {
      final data = await firestore.loadCows();

      cows.clear();

      for (final item in data) {
        final cow = Cow(
          item['name'] ?? '',
          item['birth'] ?? '',
          item['dateIn'] ?? '',
          dateOut: item['dateOut'] ?? '',
          tag: item['tag'] ?? '',
          type: item['type'] ?? 'Cow',
          breed: item['breed'] ?? 'Other',
          status: item['status'] ?? (item['dateOut'] == '' ? 'Active' : 'Sold'),
          productionStatus: item['productionStatus'] ?? 'Not producing',
          notes: item['notes'] ?? '',
          breedType: item['breedType'] ?? 'Crossbred',
          color: item['color'] ?? '',
          markings: item['markings'] ?? '',
          earTagNumber: item['earTagNumber'] ?? '',
          rfid: item['rfid'] ?? '',
          microchip: item['microchip'] ?? '',
          birthType: item['birthType'] ?? 'Unknown',
          birthWeight: item['birthWeight'] ?? '',
          damId: item['damId'] ?? '',
          sireId: item['sireId'] ?? '',
          weaningDate: item['weaningDate'] ?? '',
          weaningWeight: item['weaningWeight'] ?? '',
          acquisitionMethod: item['acquisitionMethod'] ?? 'Purchased',
          purchasePrice: item['purchasePrice'] ?? '',
          seller: item['seller'] ?? '',
          previousOwner: item['previousOwner'] ?? '',
          previousFarm: item['previousFarm'] ?? '',
          acquisitionNotes: item['acquisitionNotes'] ?? '',
          location: item['location'] ?? 'Main shed',
          herd: item['herd'] ?? '',
          lactationNumber: item['lactationNumber'] ?? '',
          lactationStartDate: item['lactationStartDate'] ?? '',
          averageDailyProduction: item['averageDailyProduction'] ?? '',
          lactationNotes: item['lactationNotes'] ?? '',
          pregnant: item['pregnant'] ?? false,
          inseminationDate: item['inseminationDate'] ?? '',
          pregnancyConfirmedDate: item['pregnancyConfirmedDate'] ?? '',
          expectedCalvingDate: item['expectedCalvingDate'] ?? '',
          breedingMethod: item['breedingMethod'] ?? 'Unknown',
          breedingSireId: item['breedingSireId'] ?? '',
          semenInformation: item['semenInformation'] ?? '',
          breedingNotes: item['breedingNotes'] ?? '',
          dryDate: item['dryDate'] ?? '',
          dryNotes: item['dryNotes'] ?? '',
          healthStatus: item['healthStatus'] ?? 'Healthy',
          lastVetVisit: item['lastVetVisit'] ?? '',
          healthNotes: item['healthNotes'] ?? '',
          estimatedValue: item['estimatedValue'] ?? '',
          acquisitionCost: item['acquisitionCost'] ?? '',
          financialNotes: item['financialNotes'] ?? '',
          identificationNotes: item['identificationNotes'] ?? '',
          specialRequirements: item['specialRequirements'] ?? '',
          photoUrl: item['photoUrl'] ?? '',
        );

        cow.id = item['id'] ?? 0;
        if (cow.tag.isEmpty)
          cow.tag = 'COW-${cow.id.toString().padLeft(3, '0')}';
        cows.add(cow);
      }

      if (cows.isNotEmpty) {
        nextCowId =
            cows.map((cow) => cow.id).reduce((a, b) => a > b ? a : b) + 1;
      } else {
        nextCowId = 1;
      }
    } catch (e) {
      debugPrint('Could not load cattle: $e');
    }
  }

  Widget _home() {
    _assignMissingCowIds();
    final pages = [
      DashboardScreen(
        cows: cows,
        feeds: feeds,
        production: production,
        expenses: expenses,
        farmer: farmer,
        open: _openTab,
        logout: _logout,
      ),
      CattleScreen(
        cows: cows,
        production: production,
        nextId: () => nextCowId++,
        changed: () => setState(() {}),
        open: _openTab,
        logout: _logout,
      ),
      FeedScreen(
        entries: feeds,
        changed: () => setState(() {}),
        open: _openTab,
        logout: _logout,
      ),
      ProductionScreen(
        cows: cows,
        entries: production,
        milkPrices: milkPrices,
        changed: () => setState(() {}),
        open: _openTab,
        logout: _logout,
      ),
      ReportsScreen(
        cows: cows,
        entries: production,
        expenses: expenses,
        milkPrices: milkPrices,
        changed: () => setState(() {}),
        open: _openTab,
        logout: _logout,
      ),
      ExpenseScreen(
        cows: cows,
        entries: expenses,
        changed: () => setState(() {}),
        open: _openTab,
        logout: _logout,
      ),
    ];
    return PopScope<void>(
      canPop: tabHistory.length <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: pages[tab],
    );
  }
}

class FarmDrawer extends StatelessWidget {
  const FarmDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.logout,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback logout;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DrawerItem('Dashboard', Icons.home_outlined, 0),
      _DrawerItem('Cattle', Icons.pets, 1),
      _DrawerItem('Feeds', Icons.grass, 2),
      _DrawerItem('Milk Production', Icons.local_drink_outlined, 3),
      _DrawerItem(
        'Finance and Reports',
        Icons.account_balance_wallet_outlined,
        4,
      ),
      _DrawerItem('Expenses', Icons.receipt_long_outlined, 5),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xff2d6a4f)),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Farm Ledger',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final item in items)
                    ListTile(
                      selected: selectedIndex == item.index,
                      selectedTileColor: Colors.green.shade50,
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      onTap: () {
                        onSelect(item.index);
                        Navigator.of(context).pop();
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: () {
                      Navigator.of(context).pop();
                      logout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.title, this.icon, this.index);
  final String title;
  final IconData icon;
  final int index;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});
  final Future<void> Function(String name) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool register = false;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.agriculture,
                    size: 64,
                    color: Color(0xff2d6a4f),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Farm Ledger',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    register
                        ? 'Create a farmer account'
                        : 'Login to your farm dashboard',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) => value == null || value.length < 4
                        ? 'Use at least 4 characters'
                        : null,
                  ),
                  if (register) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                      validator: (value) => value != password.text
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;

                            setState(() => loading = true);
                            try {
                              if (register) {
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                                      email: email.text.trim(),
                                      password: password.text,
                                    );

                                await widget.onLogin(email.text.trim());
                              } else {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                      email: email.text.trim(),
                                      password: password.text,
                                    );

                                await widget.onLogin(email.text.trim());
                              }
                            } on FirebaseAuthException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.message ?? 'Authentication failed',
                                    ),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => loading = false);
                            }
                          },
                    child: loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MilkLoadingIndicator(
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text('Loading farm...'),
                            ],
                          )
                        : Text(register ? 'Register' : 'Login'),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() => register = !register),
                    child: Text(
                      register
                          ? 'Already registered? Login'
                          : 'New farmer? Register',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MilkLoadingIndicator extends StatelessWidget {
  const MilkLoadingIndicator({
    super.key,
    this.size = 42,
    this.color = const Color(0xff2d6a4f),
  });
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(strokeWidth: size < 24 ? 2 : 3, color: color),
        Icon(Icons.local_drink_outlined, size: size * .46, color: color),
      ],
    ),
  );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.cows,
    required this.feeds,
    required this.production,
    required this.expenses,
    required this.farmer,
    required this.open,
    required this.logout,
  });
  final List<Cow> cows;
  final List<FeedEntry> feeds;
  final List<ProductionEntry> production;
  final List<ExpenseEntry> expenses;
  final String farmer;
  final void Function(int) open;
  final VoidCallback logout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String selectedMonth;

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  void initState() {
    super.initState();
    selectedMonth = monthKey(_formatDate(DateTime.now()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _showCalvingReminder());
  }

  Future<void> _showCalvingReminder() async {
    final now = DateTime.now();
    final monthKeyValue = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    Map<String, dynamic>? notification;
    try {
      notification = await FirestoreService().loadDashboardNotification(
        monthKeyValue,
      );
    } catch (error) {
      debugPrint('Could not load calving reminders: $error');
      return;
    }
    if (!mounted || notification?['dismissed'] == true) return;
    final reminders = widget.cows.where((cow) {
      if (cow.status != 'Active' || cow.expectedCalvingDate.isEmpty) return false;
      final date = _dateValue(cow.expectedCalvingDate);
      return date.isAfter(now.subtract(const Duration(days: 1))) &&
          date.isBefore(now.add(const Duration(days: 61)));
    }).toList();
    if (reminders.isEmpty) return;
    try {
      await FirestoreService().saveDashboardNotification(
        monthKey: monthKeyValue,
        calvingReminderShown: true,
        dismissed: false,
      );
    } catch (error) {
      debugPrint('Could not save calving reminder state: $error');
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calving reminders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reminders.map((cow) {
            final weeks = _dateValue(cow.expectedCalvingDate)
                .difference(now)
                .inDays ~/ 7;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${cow.name}\nExpected calving: ${cow.expectedCalvingDate}\n$weeks weeks remaining',
              ),
            );
          }).toList(),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    try {
      await FirestoreService().saveDashboardNotification(
        monthKey: monthKeyValue,
        calvingReminderShown: true,
        dismissed: true,
      );
    } catch (error) {
      debugPrint('Could not dismiss calving reminder: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _formatDate(now);
    final monthProduction = widget.production
        .where((item) => monthKey(item.date) == selectedMonth)
        .toList();
    final monthExpenses = widget.expenses
        .where((item) => monthKey(item.date) == selectedMonth)
        .toList();
    final monthFeeds = widget.feeds
        .where(
          (item) =>
              monthKey(item.month) == selectedMonth ||
              item.month == selectedMonth,
        )
        .toList();
    final milk = monthProduction.fold<double>(
      0,
      (sum, item) => sum + item.liters,
    );
    final income = monthProduction.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );
    final expenses = monthExpenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final feedCosts = monthFeeds.fold<double>(
      0,
      (sum, item) => sum + item.cost,
    );
    final totalExpenses = expenses + feedCosts;
    final profit = income - totalExpenses;
    final activeCows = widget.cows.where((cow) => cow.dateOut.isEmpty).length;
    final addedThisMonth = widget.cows
        .where((cow) => monthKey(cow.dateIn) == selectedMonth)
        .length;
    final todayProduction = widget.production
        .where((item) => item.date == today)
        .fold<double>(0, (sum, item) => sum + item.liters);
    final dailyTotals = _dailyTotals(monthProduction);
    final averageDaily = dailyTotals.isEmpty ? 0.0 : milk / dailyTotals.length;
    final totalIncome = widget.production.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );
    final expenseBreakdown = _expenseBreakdown(monthExpenses, feedCosts);
    final cowProduction = _cowProduction(monthProduction);
    final feedTrend = _feedTrend();
    final recentActivity = _recentActivity(monthProduction, monthExpenses);
    final previousMonth = _previousMonth(selectedMonth);
    final previousProduction = widget.production
        .where((item) => monthKey(item.date) == previousMonth)
        .fold<double>(0, (sum, item) => sum + item.liters);
    final previousIncome = widget.production
        .where((item) => monthKey(item.date) == previousMonth)
        .fold<double>(0, (sum, item) => sum + item.value);
    final previousFeed = widget.feeds
        .where((item) => monthKey(item.month) == previousMonth)
        .fold<double>(0, (sum, item) => sum + item.cost);
    final previousOther = widget.expenses
        .where((item) => monthKey(item.date) == previousMonth)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final alerts = <String>[];
    if (previousProduction > 0 && milk < previousProduction * .85) {
      alerts.add('Milk production is lower than last month.');
    }
    if (previousFeed > 0 && feedCosts > previousFeed * 1.1) {
      alerts.add('Feed costs increased this month.');
    }
    if (totalExpenses > income && income > 0) {
      alerts.add('Expenses are higher than milk income.');
    }
    if (widget.cows.isEmpty)
      alerts.add('Add your first cow to start tracking.');
    return Scaffold(
      drawer: FarmDrawer(
        selectedIndex: 0,
        onSelect: widget.open,
        logout: widget.logout,
      ),
      appBar: AppBar(
        title: const Text('Farm Ledger'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: widget.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardHeader(
            farmer: widget.farmer,
            date: _formatLongDate(now),
            selectedMonth: selectedMonth,
            onMonthChanged: (value) => setState(() => selectedMonth = value),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Farm at a glance',
            icon: Icons.dashboard_outlined,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 720 ? 5 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: columns == 2 ? 1.45 : 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DashboardMetric(
                      'Cattle',
                      '${widget.cows.length}',
                      'Active $activeCows',
                      Icons.pets,
                      const Color(0xff2d6a4f),
                    ),
                    _DashboardMetric(
                      'Milk this month',
                      '${milk.toStringAsFixed(1)} L',
                      'Today ${todayProduction.toStringAsFixed(1)} L • Avg ${averageDaily.toStringAsFixed(1)} L',
                      Icons.local_drink_outlined,
                      const Color(0xff267a9e),
                    ),
                    _DashboardMetric(
                      'Milk income',
                      money(income),
                      'All time ${money(totalIncome)}',
                      Icons.payments_outlined,
                      const Color(0xffb26a00),
                    ),
                    _DashboardMetric(
                      'Expenses',
                      money(totalExpenses),
                      'Feed ${money(feedCosts)}',
                      Icons.receipt_long_outlined,
                      const Color(0xffa3473c),
                    ),
                    _DashboardMetric(
                      profit >= 0 ? 'Estimated profit' : 'Estimated loss',
                      money(profit.abs()),
                      'For $selectedMonth',
                      Icons.trending_up,
                      profit >= 0
                          ? const Color(0xff2d6a4f)
                          : const Color(0xffa3473c),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Quick actions',
            icon: Icons.flash_on_outlined,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickAction(
                  'Add cattle',
                  Icons.add_circle_outline,
                  () => widget.open(1),
                ),
                _QuickAction(
                  'Record milk',
                  Icons.local_drink_outlined,
                  () => widget.open(3),
                ),
                _QuickAction(
                  'Add feed cost',
                  Icons.grass,
                  () => widget.open(2),
                ),
                _QuickAction(
                  'Add expense',
                  Icons.receipt_long_outlined,
                  () => widget.open(5),
                ),
                _QuickAction(
                  'View reports',
                  Icons.bar_chart_outlined,
                  () => widget.open(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ChartSection(
            title: 'Milk production',
            subtitle: 'Daily litres for $selectedMonth',
            child: _DashboardChart(
              values: dailyTotals.values.toList(),
              labels: dailyTotals.keys.toList(),
              color: const Color(0xff267a9e),
              suffix: ' L',
            ),
          ),
          const SizedBox(height: 16),
          _ChartSection(
            title: 'Income vs expenses',
            subtitle: 'This month compared with last month',
            child: _ComparisonBars(
              firstLabel: 'Income',
              firstValue: income,
              secondLabel: 'Expenses',
              secondValue: totalExpenses,
              color: const Color(0xff2d6a4f),
              secondColor: const Color(0xffa3473c),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 650;
              final children = [
                _ChartSection(
                  title: 'Expense breakdown',
                  subtitle: 'Where this month\'s money goes',
                  child: _BreakdownList(values: expenseBreakdown),
                ),
                _ChartSection(
                  title: 'Production by cow',
                  subtitle: 'Top producers this month',
                  child: _RankedBars(values: cowProduction, suffix: ' L'),
                ),
              ];
              return stacked
                  ? Column(
                      children: [
                        children[0],
                        const SizedBox(height: 16),
                        children[1],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 16),
                        Expanded(child: children[1]),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),
          _ChartSection(
            title: 'Feed cost trend',
            subtitle: 'Monthly feed costs',
            child: _DashboardChart(
              values: feedTrend.values.toList(),
              labels: feedTrend.keys.toList(),
              color: const Color(0xffb26a00),
              moneyValues: true,
            ),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Financial summary',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(
              children: [
                _FinanceRow('Milk income', income),
                _FinanceRow('Feed costs', feedCosts),
                _FinanceRow('Other expenses', expenses),
                const Divider(),
                _FinanceRow('Total expenses', totalExpenses, bold: true),
                _FinanceRow(
                  profit >= 0 ? 'Estimated profit' : 'Estimated loss',
                  profit.abs(),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Farm performance',
            icon: Icons.insights_outlined,
            child: Column(
              children: [
                _PerformanceRow(
                  'Milk production',
                  milk,
                  previousProduction,
                  ' L',
                ),
                _PerformanceRow('Income', income, previousIncome, ''),
                _PerformanceRow('Feed costs', feedCosts, previousFeed, ''),
                _PerformanceRow('Other expenses', expenses, previousOther, ''),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Attention',
            icon: Icons.warning_amber_outlined,
            child: alerts.isEmpty
                ? const Text('Nothing needs attention right now.')
                : Column(
                    children: alerts
                        .map(
                          (alert) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.warning_amber_outlined,
                              color: Color(0xffa3473c),
                            ),
                            title: Text(alert),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Recent activity',
            icon: Icons.history,
            child: recentActivity.isEmpty
                ? const Text('No activity recorded for this month.')
                : Column(
                    children: recentActivity
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(item.icon),
                            title: Text(item.title),
                            subtitle: Text(item.subtitle),
                            trailing: Text(item.amount),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _DashboardSection(
            title: 'Cattle overview',
            icon: Icons.pets,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _OverviewStat('Total', widget.cows.length),
                _OverviewStat('Active', activeCows),
                _OverviewStat('Out', widget.cows.length - activeCows),
                _OverviewStat('Added', addedThisMonth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLongDate(DateTime value) =>
      '${_weekday(value.weekday)}, ${_monthName(value.month)} ${value.day}, ${value.year}';

  String _weekday(int value) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][value - 1];

  String _monthName(int value) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][value - 1];

  String _previousMonth(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return value;
    var month = int.tryParse(parts[0]) ?? DateTime.now().month;
    var year = int.tryParse(parts[1]) ?? DateTime.now().year;
    month--;
    if (month == 0) {
      month = 12;
      year--;
    }
    return '${month.toString().padLeft(2, '0')}/$year';
  }

  Map<String, double> _dailyTotals(List<ProductionEntry> entries) {
    final values = <String, double>{};
    for (final entry in entries) {
      values[entry.date] = (values[entry.date] ?? 0) + entry.liters;
    }
    final sorted = values.keys.toList()..sort(_compareDates);
    final selected = sorted.length > 7
        ? sorted.sublist(sorted.length - 7)
        : sorted;
    return {for (final key in selected) key: values[key]!};
  }

  Map<String, double> _feedTrend() {
    final values = <String, double>{};
    for (final entry in widget.feeds) {
      values[monthKey(entry.month)] =
          (values[monthKey(entry.month)] ?? 0) + entry.cost;
    }
    final keys = values.keys.toList()..sort(_compareMonths);
    final selected = keys.length > 6 ? keys.sublist(keys.length - 6) : keys;
    return {for (final key in selected) key: values[key]!};
  }

  Map<String, double> _expenseBreakdown(
    List<ExpenseEntry> entries,
    double feedCosts,
  ) {
    final values = <String, double>{'Feed': feedCosts};
    for (final entry in entries) {
      final text = entry.description.toLowerCase();
      final category = text.contains('vet')
          ? 'Veterinary'
          : text.contains('med')
          ? 'Medicine'
          : text.contains('transport')
          ? 'Transport'
          : text.contains('labour') || text.contains('labor')
          ? 'Labour'
          : 'Other';
      values[category] = (values[category] ?? 0) + entry.amount;
    }
    return values..removeWhere((key, value) => value == 0);
  }

  Map<String, double> _cowProduction(List<ProductionEntry> entries) {
    final values = <String, double>{};
    for (final entry in entries) {
      final label = cowLabel(entry.cow);
      values[label] = (values[label] ?? 0) + entry.liters;
    }
    final ordered = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final entry in ordered.take(5)) entry.key: entry.value};
  }

  List<_Activity> _recentActivity(
    List<ProductionEntry> production,
    List<ExpenseEntry> expenses,
  ) {
    final activities = <_Activity>[];
    for (final entry in production) {
      activities.add(
        _Activity(
          'Milk recorded',
          '${entry.date} • ${cowLabel(entry.cow)}',
          '${entry.liters.toStringAsFixed(1)} L',
          Icons.local_drink_outlined,
        ),
      );
    }
    for (final entry in expenses) {
      activities.add(
        _Activity(
          entry.description.isEmpty ? 'Expense added' : entry.description,
          '${entry.date} • ${cowLabel(entry.cow)}',
          money(entry.amount),
          Icons.receipt_long_outlined,
        ),
      );
    }
    activities.sort((a, b) => b.subtitle.compareTo(a.subtitle));
    return activities.take(5).toList();
  }

  int _compareDates(String first, String second) =>
      _dateValue(first).compareTo(_dateValue(second));

  int _compareMonths(String first, String second) =>
      _monthValue(first).compareTo(_monthValue(second));

  DateTime _dateValue(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return DateTime(2000);
    return DateTime(
      int.tryParse(parts[2]) ?? 2000,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }

  DateTime _monthValue(String value) {
    final parts = value.split('/');
    if (parts.length != 2) return DateTime(2000);
    return DateTime(
      int.tryParse(parts[1]) ?? 2000,
      int.tryParse(parts[0]) ?? 1,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.farmer,
    required this.date,
    required this.selectedMonth,
    required this.onMonthChanged,
  });
  final String farmer;
  final String date;
  final String selectedMonth;
  final ValueChanged<String> onMonthChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Good morning, ${farmer.split('@').first}',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text('Here is your farm summary for $date.'),
      const SizedBox(height: 12),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null)
            onMonthChanged(
              monthKey(
                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}',
              ),
            );
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Showing month',
            prefixIcon: Icon(Icons.calendar_month_outlined),
            suffixIcon: Icon(Icons.arrow_drop_down),
          ),
          child: Text(selectedMonth),
        ),
      ),
    ],
  );
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric(
    this.label,
    this.value,
    this.detail,
    this.icon,
    this.color,
  );
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
  );
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _DashboardChart extends StatelessWidget {
  const _DashboardChart({
    required this.values,
    required this.labels,
    required this.color,
    this.suffix = '',
    this.moneyValues = false,
  });
  final List<double> values;
  final List<String> labels;
  final Color color;
  final String suffix;
  final bool moneyValues;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty)
      return const SizedBox(
        height: 100,
        child: Center(child: Text('No records for this period.')),
      );
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 170,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < values.length; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            moneyValues
                                ? money(values[index])
                                : '${values[index].toStringAsFixed(0)}$suffix',
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: maxValue == 0
                                ? 4
                                : 92 * values[index] / maxValue + 4,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonBars extends StatelessWidget {
  const _ComparisonBars({
    required this.firstLabel,
    required this.firstValue,
    required this.secondLabel,
    required this.secondValue,
    required this.color,
    required this.secondColor,
  });
  final String firstLabel;
  final double firstValue;
  final String secondLabel;
  final double secondValue;
  final Color color;
  final Color secondColor;

  @override
  Widget build(BuildContext context) {
    final maxValue = [firstValue, secondValue].reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        _ComparisonBar(
          label: firstLabel,
          value: firstValue,
          maxValue: maxValue,
          color: color,
        ),
        const SizedBox(height: 12),
        _ComparisonBar(
          label: secondLabel,
          value: secondValue,
          maxValue: maxValue,
          color: secondColor,
        ),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 80, child: Text(label)),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: maxValue == 0 ? 0 : value / maxValue,
            minHeight: 18,
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 80,
        child: Text(
          money(value),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

class _BreakdownList extends StatelessWidget {
  const _BreakdownList({required this.values});
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty)
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No expenses recorded.')),
      );
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    return Column(
      children: values.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    '${total == 0 ? 0 : (entry.value / total * 100).round()}%',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    money(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RankedBars extends StatelessWidget {
  const _RankedBars({required this.values, required this.suffix});
  final Map<String, double> values;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty)
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No production recorded.')),
      );
    final maxValue = values.values.reduce((a, b) => a > b ? a : b);
    return Column(
      children: values.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(entry.key, overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : entry.value / maxValue,
                      minHeight: 12,
                      color: const Color(0xff267a9e),
                      backgroundColor: const Color(0xffd8edf2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value.toStringAsFixed(1)}$suffix'),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow(this.label, this.current, this.previous, this.suffix);
  final String label;
  final double current;
  final double previous;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final change = previous == 0
        ? 0.0
        : ((current - previous) / previous) * 100;
    final rising = change >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('${current.toStringAsFixed(0)}$suffix'),
          const SizedBox(width: 12),
          Icon(
            rising ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: rising ? const Color(0xff2d6a4f) : const Color(0xffa3473c),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${change.abs().toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _Activity {
  const _Activity(this.title, this.subtitle, this.amount, this.icon);
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
}

class CattleScreen extends StatelessWidget {
  const CattleScreen({
    super.key,
    required this.cows,
    required this.production,
    required this.nextId,
    required this.changed,
    required this.open,
    required this.logout,
  });
  final List<Cow> cows;
  final List<ProductionEntry> production;
  final int Function() nextId;
  final VoidCallback changed;
  final ValueChanged<int> open;
  final VoidCallback logout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: FarmDrawer(selectedIndex: 1, onSelect: open, logout: logout),
      appBar: AppBar(title: const Text('Cattle')),
      body: cows.isEmpty
          ? const Center(child: Text('No cattle yet.'))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: cows.map((cow) {
                final entries = production.where((item) => item.cow == cow);
                final litres = entries.fold<double>(
                  0,
                  (sum, item) => sum + item.liters,
                );
                final days = entries.map((item) => item.date).toSet().length;
                final average = days == 0 ? 0 : litres / days;
                return Card(
                  child: ListTile(
                    title: Text(cow.name),
                    subtitle: Text(
                      '${cow.tag} • ${cow.breed}\n${cow.status} • ${cow.productionStatus}\nMilk ${average.toStringAsFixed(1)} L/day',
                    ),
                    isThreeLine: true,
                    leading: cow.photoUrl.isEmpty
                        ? const CircleAvatar(child: Icon(Icons.pets))
                        : CircleAvatar(
                            backgroundImage: NetworkImage(cow.photoUrl),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'View cattle profile',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => CowProfileDialog(
                              cow: cow,
                              production: production,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit cattle',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () async {
                            final edited = await showDialog<Cow>(
                              context: context,
                              builder: (_) => AddCowDialog(
                                cow: cow,
                                existingTags: cows
                                    .where((item) => item != cow)
                                    .map((item) => item.tag)
                                    .toSet(),
                              ),
                            );
                            if (edited == null) return;

                            try {
                              await FirestoreService().updateCow(
                                id: cow.id,
                                data: edited.toMap(),
                              );
                              edited.id = cow.id;
                              final index = cows.indexOf(cow);
                              cows[index] = edited;
                              changed();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not update cattle: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete cattle',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete cattle?'),
                                content: Text(
                                  'Delete ${cow.name} from the cattle list? Historical production records will remain.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            try {
                              await FirestoreService().deleteCow(cow.id);
                              cows.remove(cow);
                              changed();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cattle deleted'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not delete cattle: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final cow = await showDialog<Cow>(
            context: context,
            builder: (_) => AddCowDialog(
              suggestedTag:
                  'COW-${(cows.isEmpty ? 1 : cows.map((item) => item.id).reduce((a, b) => a > b ? a : b) + 1).toString().padLeft(3, '0')}',
              existingTags: cows.map((item) => item.tag).toSet(),
            ),
          );
          if (cow != null) {
            final firestore = FirestoreService();
            cow.id = nextId();

            try {
              await firestore.saveCow(id: cow.id, data: cow.toMap());

              cows.add(cow);
              changed();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cattle saved successfully')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not save cattle: $e')),
                );
              }
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add cattle'),
      ),
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({
    super.key,
    required this.entries,
    required this.changed,
    required this.open,
    required this.logout,
  });
  final List<FeedEntry> entries;
  final VoidCallback changed;
  final ValueChanged<int> open;
  final VoidCallback logout;

  @override
  Widget build(BuildContext context) => RecordScreen(
    title: 'Feeds',
    empty: 'No monthly feed costs yet.',
    rows: entries
        .map((item) => '${item.month}: ${money(item.cost)} monthly')
        .toList(),
    add: () async {
      final result = await showDialog<FeedEntry>(
        context: context,
        builder: (_) => const MonthlyFeedDialog(),
      );

      if (result != null) {
        final firestore = FirestoreService();

        try {
          await firestore.saveFeed(month: result.month, cost: result.cost);

          entries.add(result);
          changed();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feed cost saved successfully')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not save feed cost: $e')),
            );
          }
        }
      }
    },
    open: open,
    logout: logout,

    selectedIndex: 2,
  );
}

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({
    super.key,
    required this.cows,
    required this.entries,
    required this.milkPrices,
    required this.changed,
    required this.open,
    required this.logout,
  });
  final List<Cow> cows;
  final List<ProductionEntry> entries;
  final List<MilkPriceEntry> milkPrices;
  final VoidCallback changed;
  final ValueChanged<int> open;
  final VoidCallback logout;

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  final litres = <int, TextEditingController>{};
  late DateTime selectedDate;
  late String session;
  bool saving = false;
  bool promptedForPrice = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    session = _currentSession(selectedDate.hour);
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptForPrice());
  }

  @override
  void dispose() {
    for (final controller in litres.values) controller.dispose();
    super.dispose();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _monthKey(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _firestoreMonthKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}';

  String _currentSession(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _sessionLabel(String value) => switch (value) {
    'morning' => 'Morning',
    'afternoon' => 'Afternoon',
    _ => 'Evening',
  };

  List<Cow> get activeCows => widget.cows
      .where((cow) => cow.status == 'Active' && cow.dateOut.isEmpty)
      .toList();

  MilkPriceEntry? get currentPrice {
    final key = _monthKey(selectedDate);
    for (final price in widget.milkPrices) {
      if (price.month == key || price.month == _firestoreMonthKey(selectedDate)) {
        return price;
      }
    }
    return null;
  }

  void _ensureControllers() {
    for (final cow in activeCows) {
      litres.putIfAbsent(cow.id, () {
        final existing = widget.entries.where(
          (entry) =>
              entry.cow == cow &&
              entry.date == _date(selectedDate) &&
              entry.session == session,
        );
        return TextEditingController(
          text: existing.isEmpty ? '' : existing.first.liters.toString(),
        );
      });
    }
  }

  Future<void> _promptForPrice() async {
    if (!mounted || promptedForPrice || currentPrice != null) return;
    promptedForPrice = true;
    await _editPrice();
  }

  Future<void> _editPrice() async {
    final result = await showDialog<MilkPriceEntry>(
      context: context,
      builder: (_) => MilkPriceDialog(initialMonth: _date(selectedDate)),
    );
    if (result == null) return;
    final parts = result.month.split('/');
    final month = int.tryParse(parts.first) ?? selectedDate.month;
    final year = int.tryParse(parts.length > 1 ? parts[1] : '') ?? selectedDate.year;
    try {
      await FirestoreService().saveMilkPrice(
        monthKey: '$year-${month.toString().padLeft(2, '0')}',
        month: month,
        year: year,
        pricePerLiter: result.unitValue,
      );
      final index = widget.milkPrices.indexWhere((item) => item.month == result.month);
      if (index >= 0) {
        widget.milkPrices[index] = result;
      } else {
        widget.milkPrices.add(result);
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save milk price: $error')),
        );
      }
    }
  }

  double _todayTotal([String? selectedSession]) => widget.entries
      .where(
        (entry) =>
            entry.date == _date(selectedDate) &&
            (selectedSession == null || entry.session == selectedSession),
      )
      .fold(0, (sum, entry) => sum + entry.liters);

  double get _todayValue => widget.entries
      .where((entry) => entry.date == _date(selectedDate))
      .fold(0, (sum, entry) => sum + entry.value);

  Future<void> _saveAll() async {
    final price = currentPrice;
    if (price == null) {
      await _editPrice();
      return;
    }
    final values = <Cow, double>{};
    for (final cow in activeCows) {
      final value = double.tryParse(litres[cow.id]?.text.trim() ?? '');
      if (value != null && value >= 0) values[cow] = value;
    }
    if (values.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter litres for at least one cow.')),
      );
      return;
    }
    final duplicate = values.keys.where(
      (cow) => widget.entries.any(
        (entry) =>
            entry.cow == cow &&
            entry.date == _date(selectedDate) &&
            entry.session == session,
      ),
    );
    if (duplicate.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${cowLabel(duplicate.first)} has already been recorded for this session.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final firestore = FirestoreService();
      for (final item in values.entries) {
        final entry = ProductionEntry(
          item.key,
          _date(selectedDate),
          item.value,
          price.unitValue,
          session: session,
        );
        entry.documentId = await firestore.saveProduction(
          cowId: item.key.id,
          cowName: item.key.name,
          date: _date(selectedDate),
          year: selectedDate.year,
          month: selectedDate.month,
          day: selectedDate.day,
          session: session,
          liters: item.value,
          pricePerLiter: price.unitValue,
        );
        widget.entries.add(entry);
      }
      widget.changed();
      for (final cow in values.keys) litres[cow.id]?.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Milk production saved successfully')),
        );
        setState(() {});
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save milk production: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();
    final morning = _todayTotal('morning');
    final afternoon = _todayTotal('afternoon');
    final evening = _todayTotal('evening');
    final recordedCows = widget.entries
        .where((entry) => entry.date == _date(selectedDate))
        .map((entry) => entry.cow)
        .toSet()
        .length;
    return Scaffold(
      drawer: FarmDrawer(selectedIndex: 3, onSelect: widget.open, logout: widget.logout),
      appBar: AppBar(title: const Text('Milk Production')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Milk production', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_date(selectedDate)),
                  DropdownButton<String>(
                    value: session,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'morning', child: Text('🌅 Morning')),
                      DropdownMenuItem(value: 'afternoon', child: Text('☀️ Afternoon')),
                      DropdownMenuItem(value: 'evening', child: Text('🌙 Evening')),
                    ],
                    onChanged: (value) => setState(() => session = value ?? session),
                  ),
                  Text('Today: ${_todayTotal().toStringAsFixed(1)} L', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sell_outlined),
              title: Text(currentPrice == null ? 'Milk price needed for ${_monthKey(selectedDate)}' : 'Milk price: ${money(currentPrice!.unitValue)}/L'),
              subtitle: const Text('This price is saved with each production record.'),
              trailing: IconButton(tooltip: 'Edit monthly price', onPressed: _editPrice, icon: const Icon(Icons.edit_outlined)),
            ),
          ),
          const SizedBox(height: 12),
          _Summary('Today\'s value', money(_todayValue), Icons.payments_outlined),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: _Summary('Morning', '${morning.toStringAsFixed(1)} L', Icons.wb_sunny_outlined)), Expanded(child: _Summary('Afternoon', '${afternoon.toStringAsFixed(1)} L', Icons.light_mode_outlined)), Expanded(child: _Summary('Evening', '${evening.toStringAsFixed(1)} L', Icons.nightlight_outlined))]),
          const SizedBox(height: 8),
          Text('$recordedCows of ${activeCows.length} active cattle recorded today'),
          const SizedBox(height: 12),
          if (activeCows.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Add active cattle before recording milk.')))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Align(alignment: Alignment.centerLeft, child: Text('${_sessionLabel(session).toUpperCase()} MILKING', style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  for (final cow in activeCows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [Expanded(child: Text(cow.name, style: const TextStyle(fontWeight: FontWeight.w600))), SizedBox(width: 130, child: TextField(controller: litres[cow.id], keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Litres', suffixText: 'L')))]),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saving ? null : _saveAll, icon: saving ? const MilkLoadingIndicator(size: 20, color: Colors.white) : const Icon(Icons.save_outlined), label: Text(saving ? 'Saving...' : 'Save all'))),
                ]),
              ),
            ),
          const SizedBox(height: 16),
          Text('Recent history', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ..._historyRows(),
        ],
      ),
    );
  }

  List<Widget> _historyRows() {
    final totals = <String, double>{};
    final values = <String, double>{};
    for (final entry in widget.entries) {
      totals[entry.date] = (totals[entry.date] ?? 0) + entry.liters;
      values[entry.date] = (values[entry.date] ?? 0) + entry.value;
    }
    final dates = totals.keys.toList()..sort((a, b) => b.compareTo(a));
    return dates.take(7).map((date) => Card(child: ListTile(title: Text(date), subtitle: Text('${totals[date]!.toStringAsFixed(1)} L'), trailing: Text(money(values[date]!))))).toList();
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.cows,
    required this.entries,
    required this.expenses,
    required this.milkPrices,
    required this.changed,
    required this.open,
    required this.logout,
  });
  final List<Cow> cows;
  final List<ProductionEntry> entries;
  final List<ExpenseEntry> expenses;
  final List<MilkPriceEntry> milkPrices;
  final VoidCallback changed;
  final ValueChanged<int> open;
  final VoidCallback logout;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final search = TextEditingController();
  String? selectedDate;
  String? selectedMonth;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filteredEntries = widget.entries.where((entry) {
      final matchesText =
          query.isEmpty ||
          entry.cow.name.toLowerCase().contains(query) ||
          entry.date.toLowerCase().contains(query) ||
          monthKey(entry.date).contains(query);
      final matchesDate = selectedDate == null || entry.date == selectedDate;
      final matchesMonth =
          selectedMonth == null || monthKey(entry.date) == selectedMonth;
      return matchesText && matchesDate && matchesMonth;
    }).toList();
    final filteredExpenses = widget.expenses.where((expense) {
      final matchesText =
          query.isEmpty ||
          expense.cow.name.toLowerCase().contains(query) ||
          expense.description.toLowerCase().contains(query) ||
          expense.date.toLowerCase().contains(query) ||
          monthKey(expense.date).contains(query);
      final matchesDate = selectedDate == null || expense.date == selectedDate;
      final matchesMonth =
          selectedMonth == null || monthKey(expense.date) == selectedMonth;
      return matchesText && matchesDate && matchesMonth;
    }).toList();
    final visibleCows = widget.cows.where((cow) {
      final matchesCow = cow.name.toLowerCase().contains(query);
      if (query.isEmpty && selectedDate == null && selectedMonth == null) {
        return cow.dateOut.isEmpty;
      }
      if (matchesCow && selectedDate == null && selectedMonth == null) {
        return true;
      }
      return filteredEntries.any((entry) => entry.cow == cow) ||
          filteredExpenses.any((expense) => expense.cow == cow);
    }).toList();

    final dayLitres = filteredEntries.fold<double>(
      0,
      (sum, item) => sum + item.liters,
    );
    final dayMoney = filteredEntries.fold<double>(
      0,
      (sum, item) => sum + item.value,
    );
    final months = <String>{
      ...filteredEntries.map((entry) => monthKey(entry.date)),
      ...filteredExpenses.map((expense) => monthKey(expense.date)),
    }.toList()..sort();

    return Scaffold(
      drawer: FarmDrawer(
        selectedIndex: 4,
        onSelect: widget.open,
        logout: widget.logout,
      ),
      appBar: AppBar(title: const Text('Finance and Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Autocomplete<Cow>(
              displayStringForOption: cowLabel,
              optionsBuilder: (value) {
                final query = value.text.trim().toLowerCase();
                if (query.isEmpty) return const Iterable<Cow>.empty();
                return widget.cows.where(
                  (cow) => cow.name.toLowerCase().contains(query),
                );
              },
              onSelected: (cow) {
                search.text = cow.name;
                setState(() {});
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search cow, date, or month',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        search.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (value) {
                    search.text = value;
                    setState(() {});
                  },
                  onSubmitted: (_) => onSubmitted(),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = _formatDate(picked);
                          selectedMonth = null;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(
                            labelText: 'Filter by date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ).copyWith(
                            suffixIcon: selectedDate == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        setState(() => selectedDate = null),
                                  ),
                          ),
                      child: Text(
                        selectedDate ?? 'All dates',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedMonth = monthKey(_formatDate(picked));
                          selectedDate = null;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(
                            labelText: 'Filter by month',
                            prefixIcon: Icon(Icons.calendar_month_outlined),
                          ).copyWith(
                            suffixIcon: selectedMonth == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        setState(() => selectedMonth = null),
                                  ),
                          ),
                      child: Text(selectedMonth ?? 'All months'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Summary(
                    'Total litres',
                    '${dayLitres.toStringAsFixed(1)} L',
                    Icons.local_drink_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Summary(
                    'Total cash',
                    money(dayMoney),
                    Icons.payments_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Summary(
                    'Active cows',
                    '${visibleCows.length}',
                    Icons.pets,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Summary(
                    'Average',
                    visibleCows.isEmpty
                        ? 'KSh 0'
                        : money(dayMoney / visibleCows.length),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Per cow',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (visibleCows.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No cows are currently active.'),
                      ),
                    )
                  else
                    ...visibleCows.map((cow) {
                      final cowEntries = filteredEntries
                          .where((item) => item.cow == cow)
                          .toList();
                      final cowLitres = cowEntries.fold<double>(
                        0,
                        (sum, item) => sum + item.liters,
                      );
                      final cowMoney = cowEntries.fold<double>(
                        0,
                        (sum, item) => sum + item.value,
                      );
                      final cowExpenses = filteredExpenses
                          .where((item) => item.cow == cow)
                          .toList();
                      final expenseTotal = cowExpenses.fold<double>(
                        0,
                        (sum, item) => sum + item.amount,
                      );
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cowLabel(cow),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Born ${cow.birth}  •  In ${cow.dateIn}${cow.dateOut.isEmpty ? '  •  Active' : '  •  Out ${cow.dateOut}'}',
                              ),
                              const Divider(),
                              Text(
                                'Milk ${cowLitres.toStringAsFixed(1)} L  •  Income ${money(cowMoney)}',
                              ),
                              Text(
                                'Expenses ${money(expenseTotal)}  •  ${cowMoney - expenseTotal >= 0 ? 'Profit' : 'Loss'} ${money((cowMoney - expenseTotal).abs())}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (cowEntries.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Production details',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...cowEntries.map(
                                  (item) => Text(
                                    '${item.date}: ${item.liters.toStringAsFixed(1)} L × ${money(item.unitValue)}/L = ${money(item.value)}',
                                  ),
                                ),
                              ],
                              if (cowExpenses.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Expenses',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...cowExpenses.map(
                                  (item) => Text(
                                    '${item.date}: ${item.description} - ${money(item.amount)}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Daily records',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredEntries.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No production records found for this search.',
                        ),
                      ),
                    )
                  else
                    ...filteredEntries.map((entry) {
                      return Card(
                        child: ListTile(
                          title: Text('${entry.date} • ${cowLabel(entry.cow)}'),
                          subtitle: Text(
                            '${entry.liters.toStringAsFixed(1)} L  •  ${money(entry.unitValue)}/L',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                money(entry.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text('${entry.liters.toStringAsFixed(1)} L'),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (filteredExpenses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Expense records',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...filteredExpenses.map(
                      (expense) => Card(
                        child: ListTile(
                          title: Text(
                            '${expense.date} • ${cowLabel(expense.cow)}',
                          ),
                          subtitle: Text(expense.description),
                          trailing: Text(
                            money(expense.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Monthly records',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (months.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No monthly records found.'),
                      ),
                    )
                  else
                    ...months.map((month) {
                      final monthEntries = filteredEntries
                          .where((entry) => monthKey(entry.date) == month)
                          .toList();
                      final monthExpenses = filteredExpenses
                          .where((expense) => monthKey(expense.date) == month)
                          .toList();
                      final litres = monthEntries.fold<double>(
                        0,
                        (sum, entry) => sum + entry.liters,
                      );
                      final income = monthEntries.fold<double>(
                        0,
                        (sum, entry) => sum + entry.value,
                      );
                      final expenses = monthExpenses.fold<double>(
                        0,
                        (sum, expense) => sum + expense.amount,
                      );
                      return Card(
                        child: ListTile(
                          title: Text(month),
                          subtitle: Text(
                            '${litres.toStringAsFixed(1)} L  •  Income ${money(income)}  •  Expenses ${money(expenses)}',
                          ),
                          trailing: Text(
                            '${income - expenses >= 0 ? 'Profit' : 'Loss'}\n${money((income - expenses).abs())}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDate ??
                                selectedMonth ??
                                (query.isEmpty
                                    ? 'All totals'
                                    : 'Search totals'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Total milk: ${dayLitres.toStringAsFixed(1)} L'),
                          Text('Income: ${money(dayMoney)}'),
                          Text(
                            'Expenses: ${money(filteredExpenses.fold<double>(0, (sum, item) => sum + item.amount))}',
                          ),
                          Text(
                            '${dayMoney - filteredExpenses.fold<double>(0, (sum, item) => sum + item.amount) >= 0 ? 'Profit' : 'Loss'}: ${money((dayMoney - filteredExpenses.fold<double>(0, (sum, item) => sum + item.amount)).abs())}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilkPriceCard extends StatelessWidget {
  const _MilkPriceCard({required this.prices, required this.changed});

  final List<MilkPriceEntry> prices;
  final VoidCallback changed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.sell_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prices.isEmpty
                  ? 'Set one milk price for each month'
                  : prices
                        .map(
                          (item) => '${item.month}: ${money(item.unitValue)}/L',
                        )
                        .join('  •  '),
            ),
          ),
          IconButton(
            tooltip: 'Add monthly milk price',
            onPressed: () async {
              final result = await showDialog<MilkPriceEntry>(
                context: context,
                builder: (_) => const MilkPriceDialog(),
              );
              if (result != null) {
                try {
                  await FirestoreService().saveMilkPrice(
                    monthKey: priceMonthKey(result.month),
                    month: int.parse(result.month.split('/').first),
                    year: int.parse(result.month.split('/').last),
                    pricePerLiter: result.unitValue,
                  );
                  prices.removeWhere((item) => item.month == result.month);
                  prices.add(result);
                  changed();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Milk price saved successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not save milk price: $e')),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ),
  );
}

class MilkPriceDialog extends StatefulWidget {
  const MilkPriceDialog({super.key, this.initialMonth = ''});
  final String initialMonth;

  @override
  State<MilkPriceDialog> createState() => _MilkPriceDialogState();
}

class _MilkPriceDialogState extends State<MilkPriceDialog> {
  final form = GlobalKey<FormState>();
  final month = TextEditingController();
  final price = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialMonth.isNotEmpty) month.text = widget.initialMonth;
  }

  @override
  void dispose() {
    month.dispose();
    price.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Set monthly milk price'),
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: month,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Month',
              suffixIcon: Icon(Icons.calendar_today_outlined),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) month.text = _formatDate(picked);
            },
          ),
          const SizedBox(height: 12),
          _input(price, 'Milk price per L', true, numberField: true),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(
              context,
              MilkPriceEntry(monthKey(month.text), number(price.text)),
            );
          }
        },
        child: const Text('Save price'),
      ),
    ],
  );
}

class ProductionDialog extends StatefulWidget {
  const ProductionDialog({
    super.key,
    required this.cows,
    required this.milkPrices,
  });
  final List<Cow> cows;
  final List<MilkPriceEntry> milkPrices;

  @override
  State<ProductionDialog> createState() => _ProductionDialogState();
}

class ProductionEditDialog extends StatefulWidget {
  const ProductionEditDialog({
    super.key,
    required this.cows,
    required this.entry,
  });
  final List<Cow> cows;
  final ProductionEntry entry;

  @override
  State<ProductionEditDialog> createState() => _ProductionEditDialogState();
}

class _ProductionEditDialogState extends State<ProductionEditDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController date;
  late final TextEditingController liters;
  late final TextEditingController unitValue;
  late Cow selectedCow;

  @override
  void initState() {
    super.initState();
    selectedCow = widget.entry.cow;
    date = TextEditingController(text: widget.entry.date);
    liters = TextEditingController(text: widget.entry.liters.toString());
    unitValue = TextEditingController(text: widget.entry.unitValue.toString());
  }

  @override
  void dispose() {
    date.dispose();
    liters.dispose();
    unitValue.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit production'),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<Cow>(
              value: selectedCow,
              decoration: const InputDecoration(labelText: 'Select cow'),
              items: widget.cows
                  .map(
                    (cow) => DropdownMenuItem(
                      value: cow,
                      child: Text(cowLabel(cow)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedCow = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: date,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Production date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) date.text = _formatDate(picked);
              },
            ),
            const SizedBox(height: 12),
            _input(liters, 'Litres', true, numberField: true),
            _input(unitValue, 'Milk price per L', true, numberField: true),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(
              context,
              ProductionEntry(
                selectedCow,
                date.text.trim(),
                number(liters.text),
                number(unitValue.text),
              ),
            );
          }
        },
        child: const Text('Update production'),
      ),
    ],
  );
}

class _ProductionDialogState extends State<ProductionDialog> {
  final form = GlobalKey<FormState>();
  final date = TextEditingController();
  final litres = <Cow, TextEditingController>{};

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  void initState() {
    super.initState();
    date.text = _formatDate(DateTime.now());
  }

  @override
  void dispose() {
    date.dispose();
    for (final controller in litres.values) {
      controller.dispose();
    }
    super.dispose();
  }

  MilkPriceEntry? _priceForDate() {
    for (final price in widget.milkPrices.reversed) {
      if (price.month == monthKey(date.text)) return price;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.cows.where((cow) => cow.dateOut.isEmpty).toList();
    for (final cow in active) {
      litres.putIfAbsent(cow, TextEditingController.new);
    }

    return AlertDialog(
      title: const Text('Add daily production'),
      content: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: date,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Production date',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => date.text = _formatDate(picked));
                    }
                  },
                ),
              ),
              if (active.isEmpty)
                const Text('Add cows before recording production.')
              else ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Litres for each cow',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ...active.map(
                  (cow) => _input(
                    litres[cow]!,
                    cowLabel(cow),
                    false,
                    numberField: true,
                  ),
                ),
              ],
              if (date.text.isNotEmpty)
                Text(
                  _priceForDate() == null
                      ? 'Set the monthly milk price before saving.'
                      : 'Monthly milk price: ${money(_priceForDate()!.unitValue)}/L',
                  style: TextStyle(
                    color: _priceForDate() == null
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (active.isEmpty) {
              Navigator.pop(context);
              return;
            }
            final price = _priceForDate();
            if (price == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Set the monthly milk price first.'),
                ),
              );
              return;
            }
            if (form.currentState!.validate()) {
              final entries = active
                  .where((cow) => litres[cow]!.text.trim().isNotEmpty)
                  .map(
                    (cow) => ProductionEntry(
                      cow,
                      date.text.trim(),
                      number(litres[cow]!.text),
                      price.unitValue,
                    ),
                  )
                  .toList();
              if (entries.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter litres for at least one cow.'),
                  ),
                );
                return;
              }
              Navigator.pop(context, entries);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({
    super.key,
    required this.cows,
    required this.entries,
    required this.changed,
    required this.open,
    required this.logout,
  });
  final List<Cow> cows;
  final List<ExpenseEntry> entries;
  final VoidCallback changed;
  final ValueChanged<int> open;
  final VoidCallback logout;

  @override
  Widget build(BuildContext context) => RecordScreen(
    title: 'Other expenses',
    empty: 'No other expenses yet.',
    rows: entries
        .map(
          (item) =>
              '${item.date} • ${cowLabel(item.cow)}: ${item.description} - ${money(item.amount)}',
        )
        .toList(),
    add: () async {
      final result = await showDialog<ExpenseEntry>(
        context: context,
        builder: (_) => ExpenseDialog(cows: cows),
      );
      if (result != null) {
        final firestore = FirestoreService();

        try {
          await firestore.saveExpense(
            cowId: result.cow.id,
            date: result.date,
            description: result.description,
            amount: result.amount,
          );

          entries.add(result);
          changed();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Expense saved successfully')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not save expense: $e')),
            );
          }
        }
      }
    },
    open: open,
    logout: logout,
    selectedIndex: 5,
  );
}

class ExpenseDialog extends StatefulWidget {
  const ExpenseDialog({super.key, required this.cows});
  final List<Cow> cows;

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final form = GlobalKey<FormState>();
  final date = TextEditingController();
  final description = TextEditingController();
  final amount = TextEditingController();
  Cow? selectedCow;

  @override
  void dispose() {
    date.dispose();
    description.dispose();
    amount.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    if (widget.cows.isNotEmpty && selectedCow == null) {
      selectedCow = widget.cows.first;
    }
    return AlertDialog(
      title: const Text('Add other expense'),
      content: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.cows.isEmpty)
                const Text('Add cows before recording an expense.')
              else
                DropdownButtonFormField<Cow>(
                  value: selectedCow,
                  decoration: const InputDecoration(labelText: 'Select cow'),
                  items: widget.cows
                      .map(
                        (cow) => DropdownMenuItem(
                          value: cow,
                          child: Text(cowLabel(cow)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => selectedCow = value),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: date,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Expense date',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) date.text = _formatDate(picked);
                },
              ),
              const SizedBox(height: 12),
              _input(description, 'Description', true),
              _input(amount, 'Amount', true, numberField: true),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (widget.cows.isEmpty) {
              Navigator.pop(context);
              return;
            }
            if (form.currentState!.validate() && selectedCow != null) {
              Navigator.pop(
                context,
                ExpenseEntry(
                  selectedCow!,
                  date.text.trim(),
                  description.text.trim(),
                  number(amount.text),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({
    super.key,
    required this.cows,
    required this.feeds,
    required this.production,
    required this.expenses,
    required this.open,
    required this.logout,
  });
  final List<Cow> cows;
  final List<FeedEntry> feeds;
  final List<ProductionEntry> production;
  final List<ExpenseEntry> expenses;
  final ValueChanged<int> open;
  final VoidCallback logout;

  @override
  Widget build(BuildContext context) {
    final income = production.fold<double>(0, (sum, item) => sum + item.value);
    final feedCost = feeds.fold<double>(0, (sum, item) => sum + item.cost);
    final other = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      drawer: FarmDrawer(selectedIndex: 4, onSelect: open, logout: logout),
      appBar: AppBar(title: const Text('Finance and Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FinanceRow('Production income', income),
          _FinanceRow('Feeds', feedCost),
          _FinanceRow('Other expenses', other),
          const Divider(height: 24),
          _FinanceRow(
            income - feedCost - other >= 0 ? 'Profit' : 'Loss',
            (income - feedCost - other).abs(),
            bold: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Cow performance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ...cows.map((cow) {
            final cowIncome = production
                .where((item) => item.cow == cow)
                .fold<double>(0, (sum, item) => sum + item.value);
            final cowCost = expenses
                .where((item) => item.cow == cow)
                .fold<double>(0, (sum, item) => sum + item.amount);
            return Card(
              child: ListTile(
                title: Text(cowLabel(cow)),
                subtitle: Text(
                  'Income ${money(cowIncome)} | Costs ${money(cowCost)}',
                ),
                trailing: Text(
                  money(cowIncome - cowCost),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
          if (cows.isEmpty) const Text('Add cattle to see per-cow profit.'),
        ],
      ),
    );
  }
}

class MonthlyFeedDialog extends StatefulWidget {
  const MonthlyFeedDialog({super.key});

  @override
  State<MonthlyFeedDialog> createState() => _MonthlyFeedDialogState();
}

class _MonthlyFeedDialogState extends State<MonthlyFeedDialog> {
  final form = GlobalKey<FormState>();
  final month = TextEditingController();
  final cost = TextEditingController();

  @override
  void dispose() {
    month.dispose();
    cost.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add monthly feed cost'),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: month,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Month / date',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    month.text = _formatDate(picked);
                  }
                },
              ),
            ),
            _input(cost, 'Monthly feed cost', true, numberField: true),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(
              context,
              FeedEntry(month.text.trim(), number(cost.text)),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class AddCowDialog extends StatefulWidget {
  const AddCowDialog({
    super.key,
    this.cow,
    this.existingTags = const {},
    this.suggestedTag = '',
  });
  final Cow? cow;
  final Set<String> existingTags;
  final String suggestedTag;
  @override
  State<AddCowDialog> createState() => _AddCowDialogState();
}

class _AddCowDialogState extends State<AddCowDialog> {
  final form = GlobalKey<FormState>();
  final tag = TextEditingController();
  final name = TextEditingController();
  final birth = TextEditingController();
  final dateIn = TextEditingController();
  final dateOut = TextEditingController();
  final notes = TextEditingController();
  final color = TextEditingController();
  final markings = TextEditingController();
  final earTagNumber = TextEditingController();
  final rfid = TextEditingController();
  final microchip = TextEditingController();
  final birthWeight = TextEditingController();
  final damId = TextEditingController();
  final sireId = TextEditingController();
  final weaningDate = TextEditingController();
  final weaningWeight = TextEditingController();
  final purchasePrice = TextEditingController();
  final seller = TextEditingController();
  final previousOwner = TextEditingController();
  final previousFarm = TextEditingController();
  final acquisitionNotes = TextEditingController();
  final herd = TextEditingController();
  final lactationNumber = TextEditingController();
  final lactationStartDate = TextEditingController();
  final averageDailyProduction = TextEditingController();
  final lactationNotes = TextEditingController();
  final inseminationDate = TextEditingController();
  final pregnancyConfirmedDate = TextEditingController();
  final expectedCalvingDate = TextEditingController();
  final breedingSireId = TextEditingController();
  final semenInformation = TextEditingController();
  final breedingNotes = TextEditingController();
  final dryDate = TextEditingController();
  final dryNotes = TextEditingController();
  final lastVetVisit = TextEditingController();
  final healthNotes = TextEditingController();
  final estimatedValue = TextEditingController();
  final acquisitionCost = TextEditingController();
  final financialNotes = TextEditingController();
  final identificationNotes = TextEditingController();
  final specialRequirements = TextEditingController();
  String type = 'Cow';
  String breed = 'Other';
  String breedType = 'Crossbred';
  String birthType = 'Unknown';
  String acquisitionMethod = 'Purchased';
  String status = 'Active';
  String productionStatus = 'Not producing';
  String location = 'Main shed';
  bool pregnant = false;
  String breedingMethod = 'Unknown';
  String healthStatus = 'Healthy';

  @override
  void initState() {
    super.initState();
    final cow = widget.cow;
    if (cow != null) {
      tag.text = cow.tag;
      name.text = cow.name;
      birth.text = cow.birth;
      dateIn.text = cow.dateIn;
      dateOut.text = cow.dateOut;
      type = cow.type;
      breed = cow.breed;
      status = cow.status;
      productionStatus = cow.productionStatus;
      notes.text = cow.notes;
      breedType = cow.breedType;
      color.text = cow.color;
      markings.text = cow.markings;
      earTagNumber.text = cow.earTagNumber;
      rfid.text = cow.rfid;
      microchip.text = cow.microchip;
      birthType = cow.birthType;
      birthWeight.text = cow.birthWeight;
      damId.text = cow.damId;
      sireId.text = cow.sireId;
      weaningDate.text = cow.weaningDate;
      weaningWeight.text = cow.weaningWeight;
      acquisitionMethod = cow.acquisitionMethod;
      purchasePrice.text = cow.purchasePrice;
      seller.text = cow.seller;
      previousOwner.text = cow.previousOwner;
      previousFarm.text = cow.previousFarm;
      acquisitionNotes.text = cow.acquisitionNotes;
      location = cow.location;
      herd.text = cow.herd;
      lactationNumber.text = cow.lactationNumber;
      lactationStartDate.text = cow.lactationStartDate;
      averageDailyProduction.text = cow.averageDailyProduction;
      lactationNotes.text = cow.lactationNotes;
      pregnant = cow.pregnant;
      inseminationDate.text = cow.inseminationDate;
      pregnancyConfirmedDate.text = cow.pregnancyConfirmedDate;
      expectedCalvingDate.text = cow.expectedCalvingDate;
      breedingMethod = cow.breedingMethod;
      breedingSireId.text = cow.breedingSireId;
      semenInformation.text = cow.semenInformation;
      breedingNotes.text = cow.breedingNotes;
      dryDate.text = cow.dryDate;
      dryNotes.text = cow.dryNotes;
      healthStatus = cow.healthStatus;
      lastVetVisit.text = cow.lastVetVisit;
      healthNotes.text = cow.healthNotes;
      estimatedValue.text = cow.estimatedValue;
      acquisitionCost.text = cow.acquisitionCost;
      financialNotes.text = cow.financialNotes;
      identificationNotes.text = cow.identificationNotes;
      specialRequirements.text = cow.specialRequirements;
    } else {
      tag.text = widget.suggestedTag;
    }
  }

  @override
  void dispose() {
    tag.dispose();
    name.dispose();
    birth.dispose();
    dateIn.dispose();
    dateOut.dispose();
    notes.dispose();
    color.dispose();
    markings.dispose();
    earTagNumber.dispose();
    rfid.dispose();
    microchip.dispose();
    birthWeight.dispose();
    damId.dispose();
    sireId.dispose();
    weaningDate.dispose();
    weaningWeight.dispose();
    purchasePrice.dispose();
    seller.dispose();
    previousOwner.dispose();
    previousFarm.dispose();
    acquisitionNotes.dispose();
    herd.dispose();
    lactationNumber.dispose();
    lactationStartDate.dispose();
    averageDailyProduction.dispose();
    lactationNotes.dispose();
    inseminationDate.dispose();
    pregnancyConfirmedDate.dispose();
    expectedCalvingDate.dispose();
    breedingSireId.dispose();
    semenInformation.dispose();
    breedingNotes.dispose();
    dryDate.dispose();
    dryNotes.dispose();
    lastVetVisit.dispose();
    healthNotes.dispose();
    estimatedValue.dispose();
    acquisitionCost.dispose();
    financialNotes.dispose();
    identificationNotes.dispose();
    specialRequirements.dispose();
    super.dispose();
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
  }

  Widget _dateField(
    TextEditingController controller,
    String label,
    bool required,
    {VoidCallback? changed}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        validator: required
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            controller.text = _formatDate(picked);
            changed?.call();
          }
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    ),
  );

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  bool _validateCattle() {
    final birthDate = _parseDate(birth.text);
    final acquiredDate = _parseDate(dateIn.text);
    if (birthDate != null && acquiredDate != null &&
        acquiredDate.isBefore(birthDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acquired date cannot be before birth date.')),
      );
      return false;
    }
    final numericValues = [
      birthWeight,
      weaningWeight,
      purchasePrice,
      averageDailyProduction,
      estimatedValue,
      acquisitionCost,
    ];
    for (final controller in numericValues) {
      if (controller.text.trim().isNotEmpty && number(controller.text) < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weights and amounts cannot be negative.')),
        );
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.cow == null ? 'Add cattle' : 'Edit cattle'),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _sectionTitle('Basic information', Icons.badge_outlined),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: tag,
                decoration: const InputDecoration(
                  labelText: 'Cattle ID / tag number',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Required';
                  if (widget.existingTags.contains(text)) {
                    return 'That cattle ID is already in use';
                  }
                  return null;
                },
              ),
            ),
            _input(name, 'Cow name', true),
            _dropdown('Type', type, const [
              'Cow',
              'Bull',
              'Heifer',
              'Calf',
              'Steer',
            ], (value) => setState(() => type = value!)),
            _dropdown('Breed', breed, const [
              'Friesian',
              'Ayrshire',
              'Jersey',
              'Guernsey',
              'Crossbreed',
              'Other',
            ], (value) => setState(() => breed = value!)),
            _dropdown('Breed type', breedType, const [
              'Purebred',
              'Crossbred',
            ], (value) => setState(() => breedType = value!)),
            _input(color, 'Color', false),
            _input(markings, 'Markings', false),
            _input(earTagNumber, 'Ear tag number', false),
            _input(rfid, 'RFID / electronic ID', false),
            _input(microchip, 'Microchip number', false),
            _sectionTitle('Important dates', Icons.calendar_month_outlined),
            _dateField(
              birth,
              'Date of birth',
              true,
              changed: () {
                if (acquisitionMethod == 'Born on farm') {
                  dateIn.text = birth.text;
                }
              },
            ),
            _dropdown('Birth type', birthType, const [
              'Born on farm',
              'Purchased',
              'Gift',
              'Unknown',
            ], (value) => setState(() => birthType = value!)),
            _input(birthWeight, 'Birth weight', false, numberField: true),
            _input(damId, 'Mother / dam ID', false),
            _input(sireId, 'Father / sire ID', false),
            _dateField(weaningDate, 'Weaning date', false),
            _input(weaningWeight, 'Weaning weight', false, numberField: true),
            _sectionTitle('Acquisition', Icons.home_work_outlined),
            if (acquisitionMethod == 'Born on farm')
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date acquired / joined farm',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                ),
                child: Text(
                  birth.text.isEmpty ? 'Set date of birth first' : birth.text,
                ),
              )
            else
              _dateField(dateIn, 'Date acquired / joined farm', true),
            _dropdown('Acquisition method', acquisitionMethod, const [
              'Purchased',
              'Born on farm',
              'Gift',
              'Transfer',
              'Other',
            ], (value) {
              setState(() {
                acquisitionMethod = value!;
                if (acquisitionMethod == 'Born on farm') {
                  dateIn.text = birth.text;
                }
              });
            }),
            if (acquisitionMethod != 'Born on farm') ...[
              _input(purchasePrice, 'Purchase price', false, numberField: true),
              _input(seller, 'Seller / source', false),
              _input(previousOwner, 'Previous owner', false),
              _input(previousFarm, 'Previous farm / location', false),
            ],
            _input(acquisitionNotes, 'Acquisition notes', false),
            if (widget.cow != null)
              _dateField(dateOut, 'Date sold / left farm', false),
            _sectionTitle('Status', Icons.radio_button_checked),
            _dropdown('Status', status, const [
              'Active',
              'Sold',
              'Dead',
              'Transferred',
            ], (value) => setState(() => status = value!)),
            _dropdown('Production status', productionStatus, const [
              'Lactating',
              'Dry',
              'Pregnant',
              'Growing',
              'Breeding',
              'Not producing',
            ], (value) => setState(() => productionStatus = value!)),
            _dropdown('Current farm location', location, const [
              'Main shed',
              'Pasture',
              'Pen',
              'Other',
            ], (value) => setState(() => location = value!)),
            _input(herd, 'Herd / group', false),
            if (productionStatus == 'Lactating') ...[
              _sectionTitle('Lactation', Icons.local_drink_outlined),
              _input(lactationNumber, 'Current lactation number', false, numberField: true),
              _dateField(lactationStartDate, 'Lactation start date', false),
              _input(averageDailyProduction, 'Average daily production (L)', false, numberField: true),
              _input(lactationNotes, 'Lactation notes', false),
            ],
            if (productionStatus == 'Dry') ...[
              _sectionTitle('Dry period', Icons.pause_circle_outline),
              _dateField(dryDate, 'Date dried off', true),
              _dateField(expectedCalvingDate, 'Expected calving date', false),
              _input(dryNotes, 'Dry-period notes', false),
            ],
            if (pregnant || productionStatus == 'Pregnant' || productionStatus == 'Breeding') ...[
              _sectionTitle('Breeding', Icons.favorite_border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pregnant'),
                value: pregnant,
                onChanged: (value) => setState(() => pregnant = value),
              ),
              _dropdown('Breeding method', breedingMethod, const ['Natural mating', 'Artificial insemination', 'Unknown', 'Other'], (value) => setState(() => breedingMethod = value!)),
              _dateField(
                inseminationDate,
                'Insemination / mating date',
                false,
                changed: () {
                  if (expectedCalvingDate.text.isEmpty) {
                    final source = _parseDate(inseminationDate.text);
                    if (source != null) {
                      expectedCalvingDate.text = _formatDate(
                        source.add(const Duration(days: 283)),
                      );
                    }
                  }
                },
              ),
              _dateField(pregnancyConfirmedDate, 'Pregnancy confirmation date', false),
              _dateField(expectedCalvingDate, 'Expected calving date', false),
              _input(breedingSireId, 'Bull / sire ID', false),
              _input(semenInformation, 'Semen information', false),
              _input(breedingNotes, 'Breeding notes', false),
            ],
            _sectionTitle('Health', Icons.health_and_safety_outlined),
            _dropdown('Health status', healthStatus, const ['Healthy', 'Needs attention', 'Sick', 'Recovering', 'Unknown'], (value) => setState(() => healthStatus = value!)),
            _dateField(lastVetVisit, 'Last veterinary visit', false),
            _input(healthNotes, 'Health notes', false),
            _sectionTitle('Financial information', Icons.payments_outlined),
            _input(
              estimatedValue,
              'Initial estimated value',
              false,
              numberField: true,
            ),
            _input(acquisitionCost, 'Acquisition costs', false, numberField: true),
            _input(financialNotes, 'Financial notes', false),
            _sectionTitle('Additional information', Icons.notes_outlined),
            _input(identificationNotes, 'Identification notes', false),
            TextFormField(
              controller: notes,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'General notes'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: specialRequirements,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Special requirements',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate() && _validateCattle())
            Navigator.pop(
              context,
              Cow(
                name.text.trim(),
                birth.text.trim(),
                dateIn.text.trim(),
                dateOut: dateOut.text.trim(),
                tag: tag.text.trim(),
                type: type,
                breed: breed,
                status: status,
                productionStatus: productionStatus,
                notes: notes.text.trim(),
                breedType: breedType,
                color: color.text.trim(),
                markings: markings.text.trim(),
                earTagNumber: earTagNumber.text.trim(),
                rfid: rfid.text.trim(),
                microchip: microchip.text.trim(),
                birthType: birthType,
                birthWeight: birthWeight.text.trim(),
                damId: damId.text.trim(),
                sireId: sireId.text.trim(),
                weaningDate: weaningDate.text.trim(),
                weaningWeight: weaningWeight.text.trim(),
                acquisitionMethod: acquisitionMethod,
                purchasePrice: purchasePrice.text.trim(),
                seller: seller.text.trim(),
                previousOwner: previousOwner.text.trim(),
                previousFarm: previousFarm.text.trim(),
                acquisitionNotes: acquisitionNotes.text.trim(),
                location: location,
                herd: herd.text.trim(),
                lactationNumber: lactationNumber.text.trim(),
                lactationStartDate: lactationStartDate.text.trim(),
                averageDailyProduction: averageDailyProduction.text.trim(),
                lactationNotes: lactationNotes.text.trim(),
                pregnant: pregnant,
                inseminationDate: inseminationDate.text.trim(),
                pregnancyConfirmedDate: pregnancyConfirmedDate.text.trim(),
                expectedCalvingDate: expectedCalvingDate.text.trim(),
                breedingMethod: breedingMethod,
                breedingSireId: breedingSireId.text.trim(),
                semenInformation: semenInformation.text.trim(),
                breedingNotes: breedingNotes.text.trim(),
                dryDate: dryDate.text.trim(),
                dryNotes: dryNotes.text.trim(),
                healthStatus: healthStatus,
                lastVetVisit: lastVetVisit.text.trim(),
                healthNotes: healthNotes.text.trim(),
                estimatedValue: estimatedValue.text.trim(),
                acquisitionCost: acquisitionCost.text.trim(),
                financialNotes: financialNotes.text.trim(),
                identificationNotes: identificationNotes.text.trim(),
                specialRequirements: specialRequirements.text.trim(),
              ),
            );
        },
        child: Text(widget.cow == null ? 'Save cow' : 'Update cow'),
      ),
    ],
  );
}

class CowProfileDialog extends StatelessWidget {
  const CowProfileDialog({
    super.key,
    required this.cow,
    required this.production,
  });
  final Cow cow;
  final List<ProductionEntry> production;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey =
        '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    final entries = production.where((item) => item.cow == cow).toList();
    final todayMilk = entries
        .where((item) => item.date == todayKey)
        .fold<double>(0, (sum, item) => sum + item.liters);
    final monthMilk = entries
        .where((item) => monthKey(item.date) == monthKey(todayKey))
        .fold<double>(0, (sum, item) => sum + item.liters);
    final totalMilk = entries.fold<double>(0, (sum, item) => sum + item.liters);
    final days = entries.map((item) => item.date).toSet().length;
    final average = days == 0 ? 0 : totalMilk / days;
    return AlertDialog(
      title: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.pets)),
          const SizedBox(width: 12),
          Expanded(child: Text(cow.name)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cow.tag} • ${cow.breed}'),
            const SizedBox(height: 4),
            Text('${cow.status} • ${cow.productionStatus}'),
            const Divider(height: 24),
            const Text(
              'Basic information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Type: ${cow.type}'),
            Text('Born: ${cow.birth}'),
            Text('Acquired: ${cow.dateIn}'),
            if (cow.dateOut.isNotEmpty) Text('Left farm: ${cow.dateOut}'),
            const SizedBox(height: 12),
            const Text(
              'Production',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Today: ${todayMilk.toStringAsFixed(1)} L'),
            Text('This month: ${monthMilk.toStringAsFixed(1)} L'),
            Text('Average: ${average.toStringAsFixed(1)} L/day'),
            const SizedBox(height: 12),
            const Text('Health', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Status: ${cow.healthStatus}'),
            Text(
              'Last vet visit: ${cow.lastVetVisit.isEmpty ? 'Not recorded' : cow.lastVetVisit}',
            ),
            if (cow.healthNotes.isNotEmpty) Text(cow.healthNotes),
            const SizedBox(height: 12),
            const Text('Breeding', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Pregnant: ${cow.pregnant ? 'Yes' : 'No'}'),
            if (cow.expectedCalvingDate.isNotEmpty)
              Text('Expected calving: ${cow.expectedCalvingDate}'),
            if (cow.inseminationDate.isNotEmpty)
              Text('Insemination / mating: ${cow.inseminationDate}'),
            if (cow.productionStatus == 'Dry' && cow.dryDate.isNotEmpty)
              Text('Dried off: ${cow.dryDate}'),
            const SizedBox(height: 12),
            const Text('Financial', style: TextStyle(fontWeight: FontWeight.bold)),
            if (cow.purchasePrice.isNotEmpty)
              Text('Purchase price: ${money(number(cow.purchasePrice))}'),
            if (cow.estimatedValue.isNotEmpty)
              Text('Estimated value: ${money(number(cow.estimatedValue))}'),
            const SizedBox(height: 12),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(cow.notes.isEmpty ? 'No notes yet.' : cow.notes),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class EntryDialog<T> extends StatefulWidget {
  const EntryDialog({
    super.key,
    required this.title,
    required this.cows,
    required this.fields,
    required this.create,
  });
  final String title;
  final List<Cow> cows;
  final List<String> fields;
  final T Function(Cow cow, List<String> values) create;
  @override
  State<EntryDialog<T>> createState() => _EntryDialogState<T>();
}

class _EntryDialogState<T> extends State<EntryDialog<T>> {
  final form = GlobalKey<FormState>();
  late Cow selected = widget.cows.first;
  late final controllers = widget.fields
      .map((_) => TextEditingController())
      .toList();

  @override
  void dispose() {
    for (final controller in controllers) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<Cow>(
              value: selected,
              decoration: const InputDecoration(labelText: 'Select cow'),
              items: widget.cows
                  .map(
                    (cow) => DropdownMenuItem(
                      value: cow,
                      child: Text(cowLabel(cow)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selected = value!),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              widget.fields.length,
              (index) => _input(
                controllers[index],
                widget.fields[index],
                true,
                numberField:
                    index > 0 ||
                    widget.fields[index].toLowerCase().contains('cost'),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate())
            Navigator.pop(
              context,
              widget.create(
                selected,
                controllers.map((item) => item.text.trim()).toList(),
              ),
            );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class RecordScreen extends StatelessWidget {
  const RecordScreen({
    super.key,
    required this.title,
    required this.empty,
    required this.rows,
    required this.add,
    required this.open,
    required this.selectedIndex,
    required this.logout,
  });
  final String title;
  final String empty;
  final List<String> rows;
  final VoidCallback add;
  final ValueChanged<int> open;
  final int selectedIndex;
  final VoidCallback logout;
  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: FarmDrawer(
      selectedIndex: selectedIndex,
      onSelect: open,
      logout: logout,
    ),
    appBar: AppBar(title: Text(title)),
    body: rows.isEmpty
        ? Center(child: Text(empty))
        : ListView(
            padding: const EdgeInsets.all(12),
            children: rows
                .map((row) => Card(child: ListTile(title: Text(row))))
                .toList(),
          ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('Add entry'),
    ),
  );
}

class Cow {
  Cow(
    this.name,
    this.birth,
    this.dateIn, {
    this.dateOut = '',
    this.tag = '',
    this.type = 'Cow',
    this.breed = 'Other',
    this.status = 'Active',
    this.productionStatus = 'Not producing',
    this.notes = '',
    this.breedType = 'Crossbred',
    this.color = '',
    this.markings = '',
    this.earTagNumber = '',
    this.rfid = '',
    this.microchip = '',
    this.birthType = 'Unknown',
    this.birthWeight = '',
    this.damId = '',
    this.sireId = '',
    this.weaningDate = '',
    this.weaningWeight = '',
    this.acquisitionMethod = 'Purchased',
    this.purchasePrice = '',
    this.seller = '',
    this.previousOwner = '',
    this.previousFarm = '',
    this.acquisitionNotes = '',
    this.location = 'Main shed',
    this.herd = '',
    this.lactationNumber = '',
    this.lactationStartDate = '',
    this.averageDailyProduction = '',
    this.lactationNotes = '',
    this.pregnant = false,
    this.inseminationDate = '',
    this.pregnancyConfirmedDate = '',
    this.expectedCalvingDate = '',
    this.breedingMethod = 'Unknown',
    this.breedingSireId = '',
    this.semenInformation = '',
    this.breedingNotes = '',
    this.dryDate = '',
    this.dryNotes = '',
    this.healthStatus = 'Healthy',
    this.lastVetVisit = '',
    this.healthNotes = '',
    this.estimatedValue = '',
    this.acquisitionCost = '',
    this.financialNotes = '',
    this.identificationNotes = '',
    this.specialRequirements = '',
    this.photoUrl = '',
  });
  final String name;
  final String birth;
  final String dateIn;
  final String dateOut;
  String tag;
  String type;
  String breed;
  String status;
  String productionStatus;
  String notes;
  String breedType;
  String color;
  String markings;
  String earTagNumber;
  String rfid;
  String microchip;
  String birthType;
  String birthWeight;
  String damId;
  String sireId;
  String weaningDate;
  String weaningWeight;
  String acquisitionMethod;
  String purchasePrice;
  String seller;
  String previousOwner;
  String previousFarm;
  String acquisitionNotes;
  String location;
  String herd;
  String lactationNumber;
  String lactationStartDate;
  String averageDailyProduction;
  String lactationNotes;
  bool pregnant;
  String inseminationDate;
  String pregnancyConfirmedDate;
  String expectedCalvingDate;
  String breedingMethod;
  String breedingSireId;
  String semenInformation;
  String breedingNotes;
  String dryDate;
  String dryNotes;
  String healthStatus;
  String lastVetVisit;
  String healthNotes;
  String estimatedValue;
  String acquisitionCost;
  String financialNotes;
  String identificationNotes;
  String specialRequirements;
  String photoUrl;
  int id = 0;

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
    'tag': tag,
    'name': name,
    'type': type,
    'breed': breed,
    'breedType': breedType,
    'color': color,
    'markings': markings,
    'earTagNumber': earTagNumber,
    'rfid': rfid,
    'microchip': microchip,
    'birth': birth,
    'birthType': birthType,
    'birthWeight': birthWeight,
    'damId': damId,
    'sireId': sireId,
      'weaningDate': weaningDate,
      'weaningWeight': weaningWeight,
    'dateIn': dateIn,
    'acquisitionMethod': acquisitionMethod,
    'purchasePrice': purchasePrice,
    'seller': seller,
    'previousOwner': previousOwner,
    'previousFarm': previousFarm,
    'acquisitionNotes': acquisitionNotes,
    'dateOut': dateOut,
    'status': status,
    'productionStatus': productionStatus,
    'location': location,
    'herd': herd,
    'lactationNumber': lactationNumber,
    'lactationStartDate': lactationStartDate,
    'averageDailyProduction': averageDailyProduction,
    'lactationNotes': lactationNotes,
    'pregnant': pregnant,
    'inseminationDate': inseminationDate,
    'pregnancyConfirmedDate': pregnancyConfirmedDate,
    'expectedCalvingDate': expectedCalvingDate,
    'breedingMethod': breedingMethod,
    'breedingSireId': breedingSireId,
    'semenInformation': semenInformation,
    'breedingNotes': breedingNotes,
    'dryDate': dryDate,
    'dryNotes': dryNotes,
    'healthStatus': healthStatus,
    'lastVetVisit': lastVetVisit,
    'healthNotes': healthNotes,
    'estimatedValue': estimatedValue,
    'acquisitionCost': acquisitionCost,
    'financialNotes': financialNotes,
    'identificationNotes': identificationNotes,
    'notes': notes,
    'specialRequirements': specialRequirements,
    'photoUrl': photoUrl,
    };
    data.removeWhere((key, value) => value is String && value.isEmpty);
    return data;
  }
}

String cowLabel(Cow cow) =>
    cow.tag.isNotEmpty ? '${cow.tag} • ${cow.name}' : cow.name;

class FeedEntry {
  FeedEntry(this.month, this.cost);
  final String month;
  final double cost;
}

class MilkPriceEntry {
  MilkPriceEntry(this.month, this.unitValue);
  final String month;
  final double unitValue;
}

class ProductionEntry {
  ProductionEntry(
    this.cow,
    this.date,
    this.liters,
    this.unitValue, {
    this.documentId,
    this.session = 'morning',
  }) : value = liters * unitValue;
  final Cow cow;
  final String date;
  final double liters;
  final double unitValue;
  final double value;
  final String session;
  String? documentId;
}

class ExpenseEntry {
  ExpenseEntry(this.cow, this.date, this.description, this.amount);
  final Cow cow;
  final String date;
  final String description;
  final double amount;
}

class _Summary extends StatelessWidget {
  const _Summary(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, size: 22),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow(this.label, this.amount, {this.bold = false});
  final String label;
  final double amount;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
        Text(
          money(amount),
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    ),
  );
}

Widget _input(
  TextEditingController controller,
  String label,
  bool required, {
  bool numberField = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    keyboardType: numberField ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
        : null,
  ),
);
double number(String value) => double.tryParse(value) ?? 0;
String monthKey(String date) {
  final parts = date.split('/');
  return parts.length == 3 ? '${parts[1]}/${parts[2]}' : date;
}

String priceMonthKey(String month) {
  final parts = month.split('/');
  if (parts.length != 2) return month;
  return '${parts[1]}-${parts[0].padLeft(2, '0')}';
}

String money(double value) => 'KSh ${value.toStringAsFixed(0)}';
