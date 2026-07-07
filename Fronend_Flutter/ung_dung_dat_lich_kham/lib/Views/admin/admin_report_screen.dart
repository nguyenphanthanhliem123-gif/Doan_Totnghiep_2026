import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/report_bottom_sheet.dart';
import '../../Constants/ui_constants.dart';
import '../../models/complaint_model.dart';
import '../../viewmodels/admin_report_viewmodel.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {

  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    // Gọi API thông qua ViewModel ngay khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportViewModel>().fetchReports();
    });
  }

  // Mở BottomSheet Xử lý
  void _showHandleDialog(ComplaintModel report) {
    final noteController = TextEditingController();
    String selectedAction = 'bo_qua';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Xử lý Khiếu nại', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('Bị khiếu nại: ${report.reportedName} (${report.reportedType})', 
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
                  const SizedBox(height: 16),
                  
                  const Text('Chọn hành động xử lý:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(border: Border.all(color: kGreyTextColor.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedAction,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'bo_qua', child: Text('Bỏ qua (Dismiss)')),
                          DropdownMenuItem(value: 'canh_cao', child: Text('Gửi cảnh cáo (Warn)')),
                          DropdownMenuItem(value: 'khoa', child: Text('Khóa tài khoản (Lock)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) => setModalState(() => selectedAction = val!),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú của Admin (Lý do xử lý/Đóng case)',
                      labelStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      onPressed: () async {

                        if (noteController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập ghi chú!')));
                          return;
                        }
                        Navigator.pop(context); // Đóng bottom sheet
                        
                        // Gọi xử lý thông qua ViewModel
                        final success = await context.read<AdminReportViewModel>().handleReport(
                          reportId: report.id,
                          targetUserId: report.reportedId,
                          action: selectedAction,
                          note: noteController.text.trim(),
                        );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xử lý khiếu nại thành công!')));
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra khi xử lý.')));
                        }
                      },
                      child: const Text('Xác nhận & Đóng Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildFilterBar() {
    // Định nghĩa các trạng thái lọc
    final List<Map<String, String>> statuses = [
      {'key': 'all', 'label': 'Tất cả'},
      {'key': 'open', 'label': 'Chưa xử lý (Open)'},
      {'key': 'resolved', 'label': 'Đã giải quyết'},
      {'key': 'dismissed', 'label': 'Đã bỏ qua'},
    ];

    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = _selectedStatus == status['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                status['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: kPrimaryColor, // Sử dụng màu chủ đạo của app bạn
              backgroundColor: Colors.grey.shade100,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                ),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = status['key']!;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi trạng thái thay đổi từ ViewModel bằng context.watch
    final reportVM = context.watch<AdminReportViewModel>();

    final allReports = reportVM.reports ?? [];

    final filteredReports = allReports.where((item) {
      if (_selectedStatus == 'all') return true;
      
      return item.status?.toLowerCase() == _selectedStatus; 
    }).toList();

    return Scaffold(
      backgroundColor: kLightCyanBg2,
      appBar: AppBar(
        title: const Text('Quản lý Khiếu nại', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(),

          Expanded(
            child: reportVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : filteredReports.isEmpty
              ? Center(
                        child: Text(
                          'Không có báo cáo nào ở trạng thái này.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final item = filteredReports[index];
                    final bool isPending = item.status == 'open';
                    
                    Color statusColor = Colors.orange;
                    String statusText = 'Chờ xử lý';
                    if (item.status == 'resolved') { statusColor = Colors.green; statusText = 'Đã giải quyết'; }
                    if (item.status == 'dismissed') { statusColor = Colors.grey; statusText = 'Đã bỏ qua'; }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kBorderRadiusLarge),
                        border: Border.all(color: kGreyTextColor.withOpacity(0.1)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Case #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                          const Divider(),
                          RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.5), children: [
                            const TextSpan(text: 'Người gửi: ', style: TextStyle(color: kGreyTextColor)),
                            TextSpan(text: '${item.reporterName} (${item.reporterType})\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const TextSpan(text: 'Bị khiếu nại: ', style: TextStyle(color: kGreyTextColor)),
                            TextSpan(text: '${item.reportedName} (${item.reportedType})\n', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            const TextSpan(text: 'Lý do: ', style: TextStyle(color: kGreyTextColor)),
                            TextSpan(text: item.reason),
                          ])),
                          
                          if (!isPending && item.resolutionNote != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                              child: Text('Ghi chú Admin: ${item.resolutionNote}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                            )
                          ],

                          if (isPending) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _showHandleDialog(item),
                                icon: const Icon(Icons.gavel, size: 16, color: Colors.white),
                                label: const Text('Xử lý ngay', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16)),
                              ),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),
          )
          
        ],

      )
      
    );
  }
}