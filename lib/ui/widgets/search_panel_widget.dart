import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../features/home/home_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/services/token_storage.dart'; // Import TokenStorage

/// District model from API
class District {
  final int id;
  final String name;
  final int? cityId;

  District({
    required this.id,
    required this.name,
    this.cityId,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int,
      name: json['name'] as String,
      cityId: json['cityId'] as int?,
    );
  }
}

/// City model
class City {
  final int id;
  final String name;

  const City({
    required this.id,
    required this.name,
  });
}

/// Available cities
class Cities {
  static const almaty = City(id: 1, name: 'Алматы');
  static const astana = City(id: 2, name: 'Астана');

  static List<City> get all => [almaty, astana];
}

class SearchPanelWidget extends StatefulWidget {
  final PanelState panelState;
  final int adults;
  final int children;
  final String filter;
  final DateTime checkIn;
  final DateTime checkOut;
  final String price;

  final VoidCallback onPanelTap;
  final VoidCallback onCloseTap;
  final Function(int) onAdultsChanged;
  final Function(int) onChildrenChanged;
  final Function(String) onFilterChanged;
  final Function(DateTime) onCheckInChanged;
  final Function(DateTime) onCheckOutChanged;
  final Function(String) onPriceChanged;
  final VoidCallback onSearch;

  const SearchPanelWidget({
    Key? key,
    required this.panelState,
    required this.adults,
    required this.children,
    required this.filter,
    required this.checkIn,
    required this.checkOut,
    required this.price,
    required this.onPanelTap,
    required this.onCloseTap,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
    required this.onFilterChanged,
    required this.onCheckInChanged,
    required this.onCheckOutChanged,
    required this.onPriceChanged,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<SearchPanelWidget> createState() => SearchPanelWidgetState();
}

class SearchPanelWidgetState extends State<SearchPanelWidget> {
  // API Configuration
  static const String baseUrl = 'http://63.178.189.113:8888/api';

  int? _selectedCityId;
  String _selectedCityName = '';
  int? _selectedDistrictId;
  String _selectedDistrictName = '';

  List<District> _availableDistricts = [];
  bool _isLoadingDistricts = false;
  int? get selectedDistrictId => _selectedDistrictId;

  @override
  void initState() {
    super.initState();
    // Set default city to Almaty
    _selectedCityId = 1;
    _selectedCityName = 'Алматы';
    // Load districts for default city
    _loadDistricts(1);
  }



  /// Get access token from TokenStorage (SharedPreferences)
  Future<String?> _getAccessToken() async {
    try {
      // Use TokenStorage to get token from SharedPreferences
      final token = await TokenStorage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        debugPrint('🔑 Token found in SharedPreferences');
        debugPrint('🔑 Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

        // Check if token is expired
        final isExpired = await TokenStorage.isTokenExpired();
        if (isExpired) {
          debugPrint('⚠️ Token is expired! User needs to re-login.');
          return null;
        }

        return token;
      } else {
        debugPrint('⚠️ No token found in SharedPreferences');
        debugPrint('📋 User needs to login first');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error reading token from TokenStorage: $e');
      return null;
    }
  }

  /// Load districts from API
  Future<void> _loadDistricts(int cityId) async {
    setState(() => _isLoadingDistricts = true);

    try {
      // Get token from storage
      final token = await _getAccessToken();

      if (token == null) {
        debugPrint('❌ Cannot load districts: No access token');
        setState(() {
          _availableDistricts = [];
          _isLoadingDistricts = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/districts/by-city/$cityId'),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final districts = data.map((json) => District.fromJson(json)).toList();

        setState(() {
          _availableDistricts = districts;
          _isLoadingDistricts = false;

          // Auto-select first district if available
          if (districts.isNotEmpty) {
            _selectedDistrictId = districts[0].id;
            _selectedDistrictName = districts[0].name;
          } else {
            _selectedDistrictId = null;
            _selectedDistrictName = '';
          }
        });

        debugPrint('✅ Loaded ${districts.length} districts for city $cityId');
      } else {
        debugPrint('❌ Failed to load districts: ${response.statusCode}');
        if (response.statusCode == 401) {
          debugPrint('⚠️ Token expired or invalid. Please re-login.');
        }
        setState(() {
          _availableDistricts = [];
          _isLoadingDistricts = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading districts: $e');
      setState(() {
        _availableDistricts = [];
        _isLoadingDistricts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCollapsed = widget.panelState == PanelState.collapsed;

    return Stack(
      children: [
        // Main panel
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
                top: 40.h, left: 16.w, right: 16.w, bottom: 20.h),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          'Поиск',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (!isCollapsed)
                        Positioned(
                          right: 0,
                          child: IconButton(
                            splashRadius: 20.r,
                            onPressed: widget.onCloseTap,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 22.sp,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildDates(context),

                  if (!isCollapsed) ...[
                    SizedBox(height: 14.h),
                    _buildCounter('Кол-во гостей', widget.adults, widget.onAdultsChanged, false),
                    SizedBox(height: 14.h),

                    // City dropdown
                    _buildCityDropdown(context),
                    SizedBox(height: 10.h),

                    // District dropdown
                    _buildDistrictDropdown(context),
                    SizedBox(height: 12.h),

                    _buildFilter(),
                    SizedBox(height: 14.h),
                    _buildRecommendedPrice(),
                    SizedBox(height: 10.h),
                    _buildPriceInput(),
                  ],

                  SizedBox(height: 22.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2853AF),
                        elevation: 3,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Найти',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Transparent layer for tap on collapsed panel
        if (isCollapsed)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onPanelTap,
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  // --- Date selection ---
  Widget _buildDates(BuildContext context) {
    final dateFormat = DateFormat('d MMM, yyyy', 'ru');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Даты',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _dateCard(
                context,
                'Заезд',
                dateFormat.format(widget.checkIn),
                    () => _selectDate(context, true),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _dateCard(
                context,
                'Выезд',
                dateFormat.format(widget.checkOut),
                    () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateCard(BuildContext c, String label, String date, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 18.sp, color: const Color(0xFF2853AF)),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              date,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    DateTime selectedDate = isCheckIn ? widget.checkIn : widget.checkOut;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TableCalendar(
                      locale: 'ru_RU',
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, selectedDate),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          selectedDate = selected;
                        });
                      },
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left,
                            color: const Color(0xFF2853AF)),
                        rightChevronIcon: Icon(Icons.chevron_right,
                            color: const Color(0xFF2853AF)),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF2853AF).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF2853AF),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        defaultTextStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 14.sp,
                        ),
                        weekendTextStyle: TextStyle(
                          color: Colors.black87,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFE1E1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Отмена',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (isCheckIn)
                                widget.onCheckInChanged(selectedDate);
                              else
                                widget.onCheckOutChanged(selectedDate);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2853AF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text(
                              'Готово',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // --- Counter ---
  Widget _buildCounter(
      String label, int value, Function(int) onChanged, bool allowZero) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          Row(
            children: [
              _circleButton(
                icon: Icons.remove,
                background: const Color(0xFFEEF0F5),
                iconColor: const Color(0xFF2853AF),
                onTap: () {
                  final min = allowZero ? 0 : 1;
                  if (value > min) onChanged(value - 1);
                },
              ),
              SizedBox(width: 18.w),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(width: 18.w),
              _circleButton(
                icon: Icons.add,
                background: const Color(0xFF2853AF),
                iconColor: Colors.white,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color background,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40.r),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22.sp, color: iconColor),
      ),
    );
  }

  // --- City dropdown ---
  Widget _buildCityDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Город',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        InkWell(
          onTap: () => _showCityPicker(context),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCityName.isEmpty ? 'Выберите город' : _selectedCityName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: _selectedCityName.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black87,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    size: 24.sp, color: const Color(0xFF2853AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Выберите город',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20.h),
              ...Cities.all.map((city) {
                final isSelected = _selectedCityId == city.id;
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedCityId = city.id;
                      _selectedCityName = city.name;
                    });
                    Navigator.pop(context);
                    // Load districts for selected city
                    _loadDistricts(city.id);
                  },
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: const Color(0xFF2853AF),
                  ),
                  title: Text(
                    city.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  // --- District dropdown ---
  Widget _buildDistrictDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Район',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
        SizedBox(height: 7.h),
        InkWell(
          onTap: _isLoadingDistricts || _availableDistricts.isEmpty
              ? null
              : () => _showDistrictPicker(context),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _isLoadingDistricts
                      ? Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF2853AF),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Загрузка районов...',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    _selectedDistrictName.isEmpty
                        ? 'Выберите район'
                        : _selectedDistrictName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: _selectedDistrictName.isEmpty
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down,
                    size: 24.sp, color: const Color(0xFF2853AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDistrictPicker(BuildContext context) {
    if (_availableDistricts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Выберите район',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 400.h),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableDistricts.length,
                  itemBuilder: (context, index) {
                    final district = _availableDistricts[index];
                    final isSelected = _selectedDistrictId == district.id;
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedDistrictId = district.id;
                          _selectedDistrictName = district.name;
                        });
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: const Color(0xFF2853AF),
                      ),
                      title: Text(
                        district.name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilter() {
    final items = ['Все', 'Отель', 'Квартира'];
    final index = items.indexOf(widget.filter);

    final segmentWidth = (1.sw - 48.w) / items.length;

    return Container(
      height: 45.h,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Stack(
        children: [
          // --- ПЛАВНАЯ ПОДЛОЖКА ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            left: segmentWidth * index,
            top: 0,
            bottom: 0,
            child: Container(
              width: segmentWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // --- ТЕКСТ + КЛИК ---
          Row(
            children: items.map((i) {
              final sel = (i == widget.filter);

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onFilterChanged(i),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.black87 : Colors.black54,
                      ),
                      child: Text(i),
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }



  // --- Price ---
  Widget _buildRecommendedPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Цена',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),

      ],
    );
  }

  Widget _buildPriceInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.onPriceChanged,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 12.w, right: 8.w),
            child: Icon(Icons.wallet_outlined,
                color: const Color(0xFF2853AF), size: 22.sp),
          ),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: 'Предложи цену',
          hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        ),
      ),
    );
  }

  /// Get selected location data for search
  Map<String, dynamic> getSelectedLocation() {
    return {
      'cityId': _selectedCityId,
      'cityName': _selectedCityName.isEmpty ? null : _selectedCityName,
      'districtId': _selectedDistrictId,
      'districtName': _selectedDistrictName.isEmpty ? null : _selectedDistrictName,
    };
  }
}