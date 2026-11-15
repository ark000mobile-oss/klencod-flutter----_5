import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DebtBookApp());
}

class DebtBookApp extends StatelessWidget {
  const DebtBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دفتر الديون العالمي برو ماكس',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFF14B8A6),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainNavigation(), // فتح التطبيق مباشرة بدون شاشة دخول
    );
  }
}

// نموذج بيانات المعاملة المالية
class DebtItem {
  final String id;
  final String personName;
  final double amount;
  final bool isForMe; // true = دين لي، false = دين عليّ
  final String note;
  final DateTime date;

  DebtItem({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isForMe,
    this.note = '',
    required this.date,
  });

  DebtItem copyWith({
    String? personName,
    double? amount,
    bool? isForMe,
    String? note,
  }) {
    return DebtItem(
      id: id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      isForMe: isForMe ?? this.isForMe,
      note: note ?? this.note,
      date: date,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'amount': amount,
        'isForMe': isForMe,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory DebtItem.fromJson(Map<String, dynamic> json) => DebtItem(
        id: json['id'],
        personName: json['personName'],
        amount: json['amount'],
        isForMe: json['isForMe'],
        note: json['note'] ?? '',
        date: DateTime.parse(json['date']),
      );
}

// ================= 1. الملاحة السفلية الاحترافية =================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final String userName = 'مدير الحسابات';
  final IconData userIcon = Icons.account_balance_wallet_rounded;
  
  List<DebtItem> _debts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromDevice();
  }

  Future<void> _loadDataFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final String? debtsString = prefs.getString('saved_debts_list');
    if (debtsString != null) {
      final List decoded = jsonDecode(debtsString);
      setState(() {
        _debts = decoded.map((item) => DebtItem.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _debts = [
          DebtItem(
            id: '1',
            personName: 'أحمد صالح',
            amount: 15000,
            isForMe: true,
            note: 'سلفة نقدية لشراء معدات',
            date: DateTime.now().subtract(const Duration(days: 2)),
          ),
          DebtItem(
            id: '2',
            personName: 'بقالة الأمانة',
            amount: 4500,
            isForMe: false,
            note: 'مشتريات شهرية مؤجلة',
            date: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        _isLoading = false;
      });
      _saveDataToDevice();
    }
  }

  Future<void> _saveDataToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_debts.map((e) => e.toJson()).toList());
    await prefs.setString('saved_debts_list', encoded);
  }

  void _addOrUpdateDebt(DebtItem? existingItem, DebtItem newItem) {
    setState(() {
      if (existingItem == null) {
        _debts.insert(0, newItem);
      } else {
        final index = _debts.indexWhere((element) => element.id == existingItem.id);
        if (index != -1) {
          _debts[index] = newItem;
        }
      }
    });
    _saveDataToDevice();
  }

  void _deleteDebt(String id) {
    setState(() {
      _debts.removeWhere((item) => item.id == id);
    });
    _saveDataToDevice();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
      );
    }

    final List<Widget> pages = [
      HomePage(
        userName: userName,
        userIcon: userIcon,
        debts: _debts,
        onAddOrEdit: _addOrUpdateDebt,
        onDelete: _deleteDebt,
      ),
      AnalyticsPage(debts: _debts),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        elevation: 10,
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book, color: Color(0xFF0F766E)),
            label: 'دفتر المعاملات',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded, color: Color(0xFF0F766E)),
            label: 'التحليلات والتقارير',
          ),
        ],
      ),
    );
  }
}

// ================= 2. الصفحة الرئيسية الفخمة =================
class HomePage extends StatefulWidget {
  final String userName;
  final IconData userIcon;
  final List<DebtItem> debts;
  final Function(DebtItem?, DebtItem) onAddOrEdit;
  final Function(String) onDelete;

  const HomePage({
    super.key,
    required this.userName,
    required this.userIcon,
    required this.debts,
    required this.onAddOrEdit,
    required this.onDelete,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  String _filterType = 'all';

  double get totalForMe => widget.debts
      .where((item) => item.isForMe)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalOnMe => widget.debts
      .where((item) => !item.isForMe)
      .fold(0.0, (sum, item) => sum + item.amount);

  List<DebtItem> get filteredDebts {
    return widget.debts.where((item) {
      final matchesSearch = item.personName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.note.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (_filterType == 'for_me') {
        return matchesSearch && item.isForMe;
      } else if (_filterType == 'on_me') {
        return matchesSearch && !item.isForMe;
      }
      return matchesSearch;
    }).toList();
  }

  void _navigateToAddOrEdit({DebtItem? existingItem}) async {
    final result = await Navigator.push<DebtItem>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditDebtPage(existingItem: existingItem),
      ),
    );

    if (result != null) {
      widget.onAddOrEdit(existingItem, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingItem == null ? '✨ تمت إضافة المعاملة بنجاح وحفظها محلياً' : '✨ تم تعديل المعاملة بنجاح'),
          backgroundColor: const Color(0xFF0F766E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف نهائياً'),
        content: const Text('هل أنت متأكد من حذف هذه المعاملة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete(id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ تم حذف المعاملة بنجاح')),
              );
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _openPersonDetails(String personName) {
    final personItems = widget.debts.where((item) => item.personName == personName).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailsPage(
          personName: personName, 
          personItems: personItems,
          onDebtUpdated: () => setState(() {}),
        ),
      ),
    );
  }

  // نافذة إعدادات التطبيق والنسخ الاحتياطي
  void _showAppSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
              child: Icon(widget.userIcon, size: 35, color: const Color(0xFF0F766E)),
            ),
            const SizedBox(height: 12),
            Text(widget.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('النظام المالي المحلي المحمي', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 25),
            ListTile(
              leading: const Icon(Icons.backup_rounded, color: Color(0xFF0F766E)),
              title: const Text('نسخة احتياطية للبيانات'),
              subtitle: const Text('عرض الكود البرمجي للبيانات المخزنة'),
              onTap: () {
                Navigator.pop(context);
                final jsonString = jsonEncode(widget.debts.map((e) => e.toJson()).toList());
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('بيانات النسخ الاحتياطي'),
                    content: SelectableText(jsonString),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = totalForMe - totalOnMe;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Icon(widget.userIcon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دفتر الديون العالمي برو',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'إدارة الحسابات الشاملة',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'الإعدادات والنسخ',
            onPressed: _showAppSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة الملخص المالي المنحنية الراقية
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(35)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إجمالي لك (مستحق)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(
                              '${totalForMe.toStringAsFixed(0)} ل.ي',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('إجمالي عليك (التزام)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(
                              '${totalOnMe.toStringAsFixed(0)} ل.ي',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الصافي العام للحسابات:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '${netBalance.toStringAsFixed(0)} ل.ي',
                        style: TextStyle(
                          color: netBalance >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // شريط البحث والفلترة الذكية
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم الشخص أو الملاحظة...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0F766E)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('الكل'),
                      selected: _filterType == 'all',
                      selectedColor: const Color(0xFF14B8A6),
                      labelStyle: TextStyle(color: _filterType == 'all' ? Colors.white : Colors.black87),
                      onSelected: (val) => setState(() => _filterType = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('دين لك'),
                      selected: _filterType == 'for_me',
                      selectedColor: Colors.green.shade400,
                      labelStyle: TextStyle(color: _filterType == 'for_me' ? Colors.white : Colors.black87),
                      onSelected: (val) => setState(() => _filterType = 'for_me'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('دين عليك'),
                      selected: _filterType == 'on_me',
                      selectedColor: Colors.red.shade400,
                      labelStyle: TextStyle(color: _filterType == 'on_me' ? Colors.white : Colors.black87),
                      onSelected: (val) => setState(() => _filterType = 'on_me'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة المعاملات الاحترافية الحديثة
          Expanded(
            child: filteredDebts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 75, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد معاملات مطابقة للبحث',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: filteredDebts.length,
                    itemBuilder: (context, index) {
                      final item = filteredDebts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => _openPersonDetails(item.personName),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: item.isForMe ? Colors.green.shade50 : Colors.red.shade50,
                            child: Icon(
                              item.isForMe ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: item.isForMe ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            item.personName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(item.note, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                intl.DateFormat('yyyy/MM/dd - hh:mm a').format(item.date),
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.amount.toStringAsFixed(0)} ل.ي',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: item.isForMe ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToAddOrEdit(existingItem: item);
                                  } else if (value == 'delete') {
                                    _confirmDelete(item.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                                  const PopupMenuItem(value: 'delete', child: Text('حذف المعاملة', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddOrEdit(),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة معاملة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ================= 3. صفحة إضافة / تعديل المعاملة =================
class AddEditDebtPage extends StatefulWidget {
  final DebtItem? existingItem;
  const AddEditDebtPage({super.key, this.existingItem});

  @override
  State<AddEditDebtPage> createState() => _AddEditDebtPageState();
}

class _AddEditDebtPageState extends State<AddEditDebtPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late bool _isForMe;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingItem?.personName ?? '');
    _amountController = TextEditingController(text: widget.existingItem != null ? widget.existingItem!.amount.toString() : '');
    _noteController = TextEditingController(text: widget.existingItem?.note ?? '');
    _isForMe = widget.existingItem?.isForMe ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ الرجاء إدخال اسم صحيح ومبلغ أكبر من الصفر')),
      );
      return;
    }

    final newItem = DebtItem(
      id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      personName: name,
      amount: amount,
      isForMe: _isForMe,
      note: _noteController.text.trim(),
      date: widget.existingItem?.date ?? DateTime.now(),
    );

    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل المعاملة المالية' : 'إضافة معاملة مالية جديدة',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F766E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('حدد نوع المعاملة المالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isForMe = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isForMe ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isForMe ? Colors.green : Colors.grey.shade300,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'دين لك (مستحق)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _isForMe ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isForMe = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: !_isForMe ? Colors.red.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !_isForMe ? Colors.red : Colors.grey.shade300,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'دين عليك (التزام)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: !_isForMe ? Colors.red.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'اسم الشخص أو المؤسسة',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'المبلغ الإجمالي',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'ملاحظات إضافية (اختياري)',
                prefixIcon: const Icon(Icons.note_alt_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: _save,
                child: Text(
                  isEditing ? 'حفظ التعديلات' : 'حفظ المعاملة المالية',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 4. صفحة تفاصيل الشخص المتقدمة مع وظيفة السداد =================
class PersonDetailsPage extends StatefulWidget {
  final String personName;
  final List<DebtItem> personItems;
  final VoidCallback? onDebtUpdated;

  const PersonDetailsPage({super.key, required this.personName, required this.personItems, this.onDebtUpdated});

  @override
  State<PersonDetailsPage> createState() => _PersonDetailsPageState();
}

class _PersonDetailsPageState extends State<PersonDetailsPage> {
  late List<DebtItem> items;

  @override
  void initState() {
    super.initState();
    items = widget.personItems;
  }

  void _settleAll() async {
    final prefs = await SharedPreferences.getInstance();
    final String? debtsString = prefs.getString('saved_debts_list');
    if (debtsString != null) {
      List decoded = jsonDecode(debtsString);
      List<DebtItem> allDebts = decoded.map((e) => DebtItem.fromJson(e)).toList();
      
      allDebts.removeWhere((item) => item.personName == widget.personName);
      await prefs.setString('saved_debts_list', jsonEncode(allDebts.map((e) => e.toJson()).toList()));
    }

    setState(() {
      items.clear();
    });

    if (widget.onDebtUpdated != null) {
      widget.onDebtUpdated!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تمت تصفية وسداد كافة حسابات هذا الشخص بنجاح!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final personTotalForMe = items.where((i) => i.isForMe).fold(0.0, (s, i) => s + i.amount);
    final personTotalOnMe = items.where((i) => !i.isForMe).fold(0.0, (s, i) => s + i.amount);
    final net = personTotalForMe - personTotalOnMe;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.personName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F766E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'تصفية وسداد الحساب',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تصفية الحساب'),
                    content: Text('هل أنت متأكد من سداد وتصفية كافة الديون الخاصة بـ ${widget.personName}؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _settleAll();
                        },
                        child: const Text('تأكيد السداد'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('إجمالي له', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${personTotalForMe.toStringAsFixed(0)} ل.ي', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Container(height: 35, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text('إجمالي عليه', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${personTotalOnMe.toStringAsFixed(0)} ل.ي', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Container(height: 35, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text('الصافي النهائي', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('${net.toStringAsFixed(0)} ل.ي', style: TextStyle(color: net >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('سجل المعاملات والتفاصيل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد معاملات مسجلة أو تم سداد الحساب بالكامل'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ListTile(
                            leading: Icon(
                              item.isForMe ? Icons.arrow_downward : Icons.arrow_upward,
                              color: item.isForMe ? Colors.green : Colors.red,
                            ),
                            title: Text(
                              item.note.isNotEmpty ? item.note : (item.isForMe ? 'دين لك' : 'دين عليك'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(intl.DateFormat('yyyy/MM/dd - hh:mm a').format(item.date)),
                            trailing: Text(
                              '${item.amount.toStringAsFixed(0)} ل.ي',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: item.isForMe ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 5. صفحة التحليلات والإحصائيات الشاملة =================
class AnalyticsPage extends StatelessWidget {
  final List<DebtItem> debts;

  const AnalyticsPage({super.key, required this.debts});

  @override
  Widget build(BuildContext context) {
    final totalForMe = debts.where((i) => i.isForMe).fold(0.0, (s, i) => s + i.amount);
    final totalOnMe = debts.where((i) => !i.isForMe).fold(0.0, (s, i) => s + i.amount);
    final totalTransactions = debts.length;
    final uniquePersons = debts.map((e) => e.personName).toSet().length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('لوحة التحليلات والإحصائيات المالية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F766E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نظرة عامة ومؤشرات الأداء',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إجمالي المعاملات', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        Text('$totalTransactions معاملة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الجهات والأشخاص', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        Text('$uniquePersons جهة', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مقارنة نسب السيولة والالتزامات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: (totalForMe + totalOnMe) == 0 ? 0 : totalForMe / (totalForMe + totalOnMe),
                    backgroundColor: Colors.red.shade100,
                    color: Colors.green,
                    minHeight: 14,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('لك: ${totalForMe.toStringAsFixed(0)} ل.ي', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('عليك: ${totalOnMe.toStringAsFixed(0)} ل.ي', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
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
