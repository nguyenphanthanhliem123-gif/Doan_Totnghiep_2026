import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Constants/ui_constants.dart';
import 'package:ung_dung_dat_lich_kham/Models/paymentModel.dart';
import 'package:ung_dung_dat_lich_kham/ViewModels/payment_viewmodel.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>{
  // 1. Khai báo biến lưu trạng thái lọc hiện tại
  String _selectedStatus = 'Tất cả';

  // 2. Danh sách các trạng thái để hiển thị trên thanh lọc
  final List<String> _statusOptions = [
    'Tất cả',
    'Thành công',
    'Đang chờ',
    'Thất bại',
    'Đã hoàn tiền',
    'Hoàn tiền thất bại'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewmodel>().fetchPaymentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsVM = context.watch<PaymentViewmodel>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Hiển thị thanh lọc trạng thái
          _buildFilterChips(),
          
          // Hiển thị nội dung danh sách
          Expanded(child: _buildBody(transactionsVM)),
        ],
      ),
    );
  }

  // Widget hiển thị thanh lọc (vuốt ngang được)
  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: _statusOptions.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                backgroundColor: Colors.grey[200],
                selectedColor: kPrimaryColor.withOpacity(0.2),
                checkmarkColor: kPrimaryColor,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: isSelected ? kPrimaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Hàm xử lý các trạng thái giao diện và danh sách
  Widget _buildBody(PaymentViewmodel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) {
      return Center(
        child: Text(
          'Lỗi: ${vm.errorMessage}',
          style: const TextStyle(color: Colors.red, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (vm.listPayment == null || vm.listPayment!.isEmpty) {
      return const Center(
        child: Text(
          'Bạn chưa có giao dịch nào.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 3. THỰC HIỆN LỌC DỮ LIỆU
    List<PaymentModel> filteredList = vm.listPayment!;
    if (_selectedStatus != 'Tất cả') {
      filteredList = filteredList.where((transaction) {
        // So sánh không phân biệt hoa thường để tránh lỗi dữ liệu từ API
        return transaction.trangThai.toLowerCase() == _selectedStatus.toLowerCase();
      }).toList();
    }

    // 4. Nếu sau khi lọc mà danh sách rỗng
    if (filteredList.isEmpty) {
      return const Center(
        child: Text(
          'Không có giao dịch nào phù hợp.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 5. Hiển thị danh sách ĐÃ LỌC
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final transaction = filteredList[index];
        return TransactionCard(transaction: transaction);
      },
    );
  }
}

// Widget thẻ giao dịch
class TransactionCard extends StatelessWidget {
  final PaymentModel transaction;

  const TransactionCard({Key? key, required this.transaction}) : super(key: key);

  // Đã cập nhật thêm màu cho các trạng thái hoàn tiền
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'thành công':
        return Colors.green;
      case 'đang chờ':
        return Colors.orange;
      case 'thất bại':
        return Colors.red;
      case 'đã hoàn tiền':
        return Colors.purple; // Màu tím cho hoàn tiền thành công
      case 'hoàn tiền thất bại':
        return Colors.deepOrange; // Màu cam đậm cho hoàn tiền thất bại
      default:
        return Colors.grey;
    }
  }

  Widget _getMethodIcon(String method) {
    IconData iconData;
    Color iconColor;

    if (method.toLowerCase().contains('Ví VNPay')) {
      iconData = Icons.account_balance_wallet;
      iconColor = Colors.pink;
    } else if (method.toLowerCase().contains('Tiền mặt')) {
      iconData = Icons.account_balance;
      iconColor = Colors.blue;
    } else {
      iconData = Icons.payments; 
      iconColor = Colors.teal;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _getMethodIcon(transaction.phuongThuc),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.maLichHenChu,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(transaction.thoiGianGiaoDich),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(transaction.gia),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Phương thức: ${transaction.phuongThuc}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.trangThai).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transaction.trangThai,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(transaction.trangThai),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}