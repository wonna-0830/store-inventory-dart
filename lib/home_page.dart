import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_check/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //오늘의 발주 리스트를 저장하는 리스트 (재료명, 남은 수량, 발주할 수량 등)
  final List<Map<String, dynamic>> todayOrders = [];
  //오늘 날짜 가져오기
  DateTime today = DateTime.now(); // 오늘 날짜 (고정)
  DateTime selectedDate = DateTime.now(); // 사용자가 선택한 날짜
  DateTime baseDate = DateTime.now(); // 캘린더 기준 날짜 (기본은 오늘, 팝업에서 바뀜)

  String? userName;
  String? userStore;

  @override
  void initState() {
    super.initState();
    fetchTodayOrders();
    _loadUserBasics();
  }

  Future<void> _loadUserBasics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName  = prefs.getString('userName');
      userStore = prefs.getString('userStore');
    });
  }

  //발주 목록 관리 버튼을 눌렀을 때 호출 -> IngredientManagePage로 이동
  void _navigateToManagePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientManagePage(supabase: supabase),
      ),
    );
  }

  void _showIngredientPickerDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final response = await supabase
        .from('ingredients')
        .select('id, name, category, is_common, user_id')
        .or('is_common.is.true,user_id.eq.$userId')
        .order('category')
        .order('name', ascending: true);

    final List<Map<String, dynamic>> ingredientItems =
    List<Map<String, dynamic>>.from(response);

    Widget buildCategorySection(String category, List<Map<String, dynamic>> items) {
      final filtered = items.where((e) => e['category'] == category).toList();
      if (filtered.isEmpty) return SizedBox();

      return ExpansionTile(
        title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
        children: filtered.map((item) => ListTile(
          title: Text(item['name']),
          onTap: () {
            Navigator.pop(context);

            if (!todayOrders.any((o) => o['name'] == item['name'])) {
              setState(() {
                todayOrders.add({
                  'name': item['name'],
                  'quantity': '',
                  'controller': TextEditingController(),
                  'source': 'new',
                  'editing': true,
                });
              });
            }
          },
        )).toList(),
      );
    }


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('재료 선택'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: [
                buildCategorySection('냉동', ingredientItems),
                buildCategorySection('냉장', ingredientItems),
                buildCategorySection('소스', ingredientItems),
                buildCategorySection('포장', ingredientItems),
                buildCategorySection('야채', ingredientItems),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기'),
            )
          ],
        );
      },
    );
  }


  //재료의 발주 수량을 업데이트
  void _updateQuantity(int index, String value) {
    setState(() {
      todayOrders[index]['quantity'] = value;
    });
  }

  //삭제버튼 클릭 시 해당 재료를 리스트에서 제거
  void _removeIngredient(int index) async {
    final item = todayOrders[index];

    // DB에서 온 항목만 삭제 API 호출
    if (item['source'] == 'db') {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      await supabase
          .from('daily_orders')
          .delete()
          .match({
        'name': item['name'],
        'date': item['date'],
        'user_id': userId!,
      });
    }

    setState(() {
      todayOrders.removeAt(index); // 리스트에서 제거
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item['name']} 발주가 삭제되었습니다")),
    );
  }


  Future<void> fetchTodayOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final today = DateTime.now();
    final formattedDate = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final response = await supabase
        .from('daily_orders')
        .select()
        .eq('date', formattedDate)
        .eq('user_id', userId!)
        .order('name', ascending: true);

    setState(() {
      todayOrders.clear();
      todayOrders.addAll(List<Map<String, dynamic>>.from(
        response.map((e) => {
          ...(e as Map<String, dynamic>),
          'controller': TextEditingController(text: e['quantity']?.toString() ?? ''),
          'source': 'db',
        }),
      ));
    });
  }

  Future<void> fetchTodayOrdersByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final response = await supabase
        .from('daily_orders')
        .select()
        .eq('date', formattedDate)
        .eq('user_id', userId!)
        .order('name', ascending: true);

    setState(() {
      todayOrders.clear();
      todayOrders.addAll(List<Map<String, dynamic>>.from(
        response.map((e) => {
          ...(e as Map<String, dynamic>),
          'controller': TextEditingController(text: e['quantity']?.toString() ?? ''),
          'source': 'db',
        }),
      ));
    });
  }

  //[확인] 버튼을 누르면 실행, 입력된 수량을 DB로 반영
  Future<void> _confirmOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    await supabase
        .from('daily_orders')
        .delete()
        .eq('date', formattedDate)
        .eq('user_id', userId!);

    for (var order in todayOrders) {
      final name = order['name'];
      final rawQuantity = order['quantity'];
      final quantity = rawQuantity is int
          ? rawQuantity
          : int.tryParse(rawQuantity ?? '0') ?? 0;

      if (quantity > 0) {
        await supabase.from('daily_orders').insert({
          'user_id': userId,
          'name': name,
          'quantity': quantity,
          'date': formattedDate,
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('발주가 저장되었습니다!')),
    );
  }


  //오늘 기준 5일간 날짜를 리스트로 만듦
  List<DateTime> getFiveDayRange(DateTime base) {
    return List.generate(5, (i) => base.subtract(Duration(days: 3 - i)));
  }

  void _showMonthlyCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ko'),
    );

    if (picked != null) {
      onMonthlyCalendarDatePicked(picked);
    }
  }
  void onMonthlyCalendarDatePicked(DateTime pickedDate) {
    setState(() {
      selectedDate = pickedDate;
      baseDate = pickedDate;
    });
    fetchTodayOrdersByDate(pickedDate);
  }


  @override
  Widget build(BuildContext context) {
    final weekDates = getFiveDayRange(baseDate);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            showMenu<String>(
              context: context,
              position: const RelativeRect.fromLTRB(0, kToolbarHeight, 0, 0),
              items: [
                PopupMenuItem<String>(
                  enabled: false,
                  // 예) 사용자: 박정원 (마산어쩌고)
                  child: Text(
                    "사용자: ${userName ?? '-'}${userStore != null ? ' (${userStore})' : ''}",
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: "logout",
                  child: Text("로그아웃"),
                ),
              ],
            ).then((value) async {
              if (value == "logout") {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("로그아웃 확인"),
                    content: const Text("정말 로그아웃 하시겠습니까?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("로그아웃", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('userId');
                  await prefs.remove('userName');
                  await prefs.remove('userStore');
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            });

          },
          child: const Text("담꾹 전용 발주 도우미"),
        ),
        actions: [
          TextButton(
            onPressed: _navigateToManagePage,
            child: Text("발주 목록 관리", style: TextStyle(color: Colors.black)),
          )
        ],
      ),

      //앱 몸체
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column( //세로로 정렬
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row( //이 안에 들어가는 UI는 나란히 정렬 (가로로, Text + Button)
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("🛒 ${DateFormat('MM월 dd일').format(selectedDate)} 발주 리스트",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _showIngredientPickerDialog,
                  icon: Icon(Icons.add),
                )
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: todayOrders.length,
                  itemBuilder: (context, index) {
                    final item = todayOrders[index];
                    // 수량 입력을 위한 TextEditingController
                    final controller = item['controller'] as TextEditingController;
                    controller.text = item['quantity'].toString();
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 3),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(item['name'], style: TextStyle(fontSize: 18)),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    item['quantity'] = val;
                                    item['editing'] = true;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: '수량',
                                  isDense: true,
                                  border: item['editing'] == true
                                      ? UnderlineInputBorder()
                                      : InputBorder.none,
                                ),
                              ),

                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text("삭제 확인"),
                                    content: Text("${item['name']} 발주를 삭제할까요?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("취소")),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _removeIngredient(index);
                                        },
                                        child: Text("삭제", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  }

              ),
            ),
            SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("저장 확인"),
                      content: Text("해당 내용으로 발주 내역을 저장하시겠습니까?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("취소"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text("저장", style: TextStyle(color: Colors.teal)),
                        ),
                      ],
                    ),
                  );

                  Future.delayed(Duration(milliseconds: 50), () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  });

                  // 사용자가 저장을 눌렀을 때만 실행!
                  if (confirm == true) {
                    await _confirmOrder();
                  }
                },
                child: Text("확인"),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "📅 이번 주 캘린더",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showMonthlyCalendar, // 날짜 고르는 함수 연결
                  icon: Icon(Icons.calendar_today, size: 18),
                  label: Text("전체 보기", style: TextStyle(fontSize: 14)),
                ),
              ],
            ),SizedBox(height: 8),
            Row(
              children: weekDates.map((date) {
                final isSelected = date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

                return Expanded(
                  child: Column(
                    children: [
                      Text(DateFormat.E().format(date)), // 요일 (Sun, Mon 등)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.teal : Colors.grey[300],
                          foregroundColor: isSelected ? Colors.white : Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          setState(() => selectedDate = date);
                          fetchTodayOrdersByDate(date); // 발주 내역 가져오기
                        },

                        child: Text("${date.day}"),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )

          ],
        ),
      ),
    );
  }
}

class IngredientManagePage extends StatefulWidget {
  final SupabaseClient supabase;

  const IngredientManagePage({super.key, required this.supabase});

  @override
  State<IngredientManagePage> createState() => _IngredientManagePageState();
}

class _IngredientManagePageState extends State<IngredientManagePage> {
  final TextEditingController nameController = TextEditingController();
  List<Map<String, dynamic>> ingredients = [];

  @override
  void initState() {
    super.initState();
    fetchIngredients();
  }

  void _showDeleteDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("정말 삭제할까요?"),
        content: Text("재료 '$name' 을(를) 삭제하시겠어요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 닫기
            child: Text("취소"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫고
              deleteIngredient(id);   // 삭제 실행
            },
            child: Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  // 재료 목록 불러오기
  Future<void> fetchIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final response = await supabase
        .from('ingredients')
        .select()
        .order('category')
        .order('name', ascending: true);

    print(response);

    setState(() {
      ingredients = List<Map<String, dynamic>>.from(response);
    });
  }


  // 재료 이름만 등록
  String? selectedCategory;

  Future<void> insertIngredient() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final name = nameController.text.trim();
    if (name.isEmpty || selectedCategory == null) return;

    await widget.supabase.from('ingredients').insert({
      'user_id': userId,
      'name': name,
      'category': selectedCategory,
      'is_common': false
    });

    nameController.clear();
    setState(() {
      selectedCategory = null;
    });
    fetchIngredients();
  }


  // 삭제 기능
  Future<void> deleteIngredient(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    await widget.supabase
        .from('ingredients')
        .delete()
        .eq('id', id)
        .eq('user_id', userId!);

    fetchIngredients();
  }

  Widget buildCategorySection(String category, List<Map<String, dynamic>> items) {
    final filtered = items.where((e) => e['category'] == category).toList();
    if (filtered.isEmpty) return SizedBox();

    return ExpansionTile(
      title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
      children: filtered.map((item) => ListTile(
        title: Text(item['name']),
        trailing: item['is_common'] == true
            ? null // 공통 품목은 삭제 불가
            : IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteDialog(item['id'], item['name']),
        ),
      )).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('발주 재료 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 입력창 (이름만) — 공간이 좁아질 경우에도 안전하게 표시되도록 개선
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text('카테고리'),
                    items: ['냉동', '냉장', '소스', '포장', '야채']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedCategory = val);
                    },
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: '재료 이름'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: insertIngredient,
                  child: Text('추가'),
                )
              ],
            ),
            SizedBox(height: 24),

            // 등록된 재료 리스트
            Expanded(
              child: ListView(
                children: [
                  buildCategorySection('냉동', ingredients),
                  buildCategorySection('냉장', ingredients),
                  buildCategorySection('소스', ingredients),
                  buildCategorySection('포장', ingredients),
                  buildCategorySection('야채', ingredients),
                ],
              ),
            )
          ],
        ),
      ),
    );

  }
}
