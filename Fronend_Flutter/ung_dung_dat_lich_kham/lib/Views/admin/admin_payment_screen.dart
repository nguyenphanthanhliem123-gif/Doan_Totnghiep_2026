import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ung_dung_dat_lich_kham/Models/payment_admin_model.dart';
import '../../Constants/ui_constants.dart';
import '../../viewmodels/admin_payment_viewmodel.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({Key? key}) : super(key: key);

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminPaymentViewModel>().fetchAllPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminPaymentViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quản lý thanh toán',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(vm),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.filteredPayments.isEmpty
                    ? const Center(child: Text("Không có dữ liệu thanh toán"))
                    : ListView.builder(
                        itemCount: vm.filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = vm.filteredPayments[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                payment.tenNguoiDung ?? 'Khách',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Mã GD: ${payment.maGiaoDich ?? 'Chưa có'}"),
                                  Text("Booking: ${payment.maBooking ?? ''}"),
                                  Text("Số tiền: ${currencyFormat.format(payment.tongTien)}"),
                                  Text("PT: ${payment.phuongThuc.toUpperCase()} - Trạng thái: ${_translateStatus(payment.trangThai)}"),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showUpdateStatusDialog(context, payment),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AdminPaymentViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => vm.searchByName(val),
            decoration: const InputDecoration(
              labelText: "Tìm theo tên khách hàng",
              prefixIcon: Icon(Icons.person_search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (val) => vm.searchByTransactionId(val),
                  decoration: const InputDecoration(
                    labelText: "Tìm theo mã GD",
                    prefixIcon: Icon(Icons.receipt_long),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: vm.filterStatus,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text("Tất cả")),
                    DropdownMenuItem(value: 'pending', child: Text("Chờ TT")),
                    DropdownMenuItem(value: 'paid', child: Text("Đã thanh toán")),
                    DropdownMenuItem(value: 'refunded', child: Text("Đã hoàn tiền")),
                    DropdownMenuItem(value: 'failed', child: Text("Thất bại")),
                  ],
                  onChanged: (val) {
                    if (val != null) vm.setStatusFilter(val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending': return 'Chờ thanh toán';
      case 'paid': return 'Đã thanh toán';
      case 'refunded': return 'Đã hoàn tiền';
      case 'failed': return 'Thất bại';
      case 'refund_fail': return 'Hoàn tiền lỗi';
      default: return status;
    }
  }

  void _showUpdateStatusDialog(BuildContext context, PaymentAdminModel payment) {
    String selectedStatus = payment.trangThai;
    final TextEditingController reasonController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cập nhật trạng thái"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Trạng thái mới",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text("Chờ thanh toán (pending)")),
                    DropdownMenuItem(value: 'paid', child: Text("Đã thanh toán (paid)")),
                    DropdownMenuItem(value: 'refunded', child: Text("Đã hoàn tiền (refunded)")),
                    DropdownMenuItem(value: 'failed', child: Text("Thất bại (failed)")),
                  ],
                  onChanged: (val) => selectedStatus = val!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: "Lý do thay đổi (* Bắt buộc)",
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập lý do để ghi Log';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                // Kiểm tra Validate: Nếu đã nhập Lý do thì mới cho chạy
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context); // Đóng Dialog trước
                  
                  // Gọi ViewModel cập nhật (bọc trong Provider)
                  final success = await context.read<AdminPaymentViewModel>().updatePaymentStatus(
                    payment.maThanhToan,
                    selectedStatus,
                    payment.maNguoiDung ?? 0, 
                    reasonController.text.trim(),
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? "Cập nhật thành công!" : "Cập nhật thất bại. Vui lòng thử lại!"),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Lưu thay đổi"),
            ),
          ],
        );
      },
    );
  }
}