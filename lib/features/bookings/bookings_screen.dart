import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// BookingsScreen - displays active and history bookings
/// Shows empty state when no bookings available
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - empty for now
  final List<dynamic> _activeBookings = [];
  final List<dynamic> _historyBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Мои брони',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),
          SizedBox(height: 16.h),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active bookings tab
                _buildBookingsList(_activeBookings, isActive: true),
                // History bookings tab
                _buildBookingsList(_historyBookings, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab selector widget (Активные / История)
  Widget _buildTabSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF1A1A1A),
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Активные'),
          Tab(text: 'История'),
        ],
      ),
    );
  }

  /// Bookings list or empty state
  Widget _buildBookingsList(List<dynamic> bookings, {required bool isActive}) {
    if (bookings.isEmpty) {
      return _buildEmptyState(isActive);
    }

    // TODO: Build actual booking cards when data is available
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        // Placeholder for booking card
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Text('Booking card'),
        );
      },
    );
  }

  /// Empty state widget
  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 56.sp,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24.h),

          // Text
          Text(
            'Брони отсутствуют',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Text(
              isActive
                  ? 'У вас пока нет активных бронирований.\nНачните поиск жилья!'
                  : 'История бронирований пуста.\nСовершите первое бронирование!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 32.h),

          // Action button
          if (isActive)
            ElevatedButton(
              onPressed: () {
                // Navigate to home tab (search)
                // This will be handled by parent MainScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF295CDB),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Найти жильё',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}