import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_detail_screen.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_list_screen.dart';
import 'package:ung_dung_dat_lich_kham/viewmodels/search_viewmodel.dart';
import '../constants/ui_constants.dart';


class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🌟 Tải lịch sử tìm kiếm từ LocalStorage ngay khi vừa vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().loadSearchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchVM = context.watch<SearchViewModel>();
    final results = searchVM.searchResults;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true, 
          decoration: InputDecoration(
            hintText: 'Tìm bác sĩ, chuyên khoa, phòng khám...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
          onChanged: (value) {
            context.read<SearchViewModel>().onSearchQueryChanged(value);
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                context.read<SearchViewModel>().onSearchQueryChanged('');
              },
            )
        ],
      ),
      body: searchVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _searchController.text.isEmpty
              ? _buildHistoryOrEmptyState(searchVM) // 🌟 THAY ĐỔI Ở ĐÂY
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- HIỂN THỊ KẾT QUẢ BÁC SĨ ---
                    if (results['doctors'].isNotEmpty) ...[
                      const Text('👨‍⚕️ Bác sĩ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...results['doctors'].map((doc) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: doc['Anh_dai_dien'] != null ? NetworkImage(doc['Anh_dai_dien']) : null,
                          child: doc['Anh_dai_dien'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(doc['Ten_bac_si'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(doc['Ten_chuyen_khoa'] ?? 'Chưa rõ khoa'),
                        onTap: () {
                          if(!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: doc['Ma_bac_si']),)
                          );
                        },
                      )).toList(),
                      const Divider(height: 30),
                    ],

                    // --- HIỂN THỊ KẾT QUẢ CHUYÊN KHOA ---
                    if (results['specialties'].isNotEmpty) ...[
                      const Text('🩺 Chuyên khoa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...results['specialties'].map((spec) => ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: kPrimaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.local_hospital, color: kPrimaryColor),
                        ),
                        title: Text(spec['Ten_chuyen_khoa'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          if(!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => DoctorListScreen(specialtyId: spec['Ma_chuyen_khoa'],))
                          );
                        },
                      )).toList(),
                      const Divider(height: 30),
                    ],

                    // --- HIỂN THỊ KẾT QUẢ PHÒNG KHÁM ---
                    if (results['clinics'].isNotEmpty) ...[
                      const Text('🏥 Phòng khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 10),
                      ...results['clinics'].map((clinic) => ListTile(
                        leading: const Icon(Icons.business_rounded, color: Colors.blueGrey, size: 30),
                        title: Text(clinic['Ten_phong_kham'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(clinic['Dia_chi'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          // Điều hướng tới chi tiết phòng khám
                        },
                      )).toList(),
                    ],

                    // --- KHÔNG CÓ KẾT QUẢ NÀO ---
                    if (results['doctors'].isEmpty && results['specialties'].isEmpty && results['clinics'].isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text('Không tìm thấy kết quả nào phù hợp.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                  ],
                ),
    );
  }

  // 🌟 GIAO DIỆN MỚI: Nếu có lịch sử thì hiển thị, nếu trống hoàn toàn thì hiện empty state cũ
  Widget _buildHistoryOrEmptyState(SearchViewModel searchVM) {
    if (searchVM.searchHistory.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🕒 Lịch sử tìm kiếm gần đây',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
              ),
              TextButton(
                onPressed: () => searchVM.clearSearchHistory(),
                child: const Text('Xóa hết', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchVM.searchHistory.length,
            itemBuilder: (context, index) {
              final historyItem = searchVM.searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.black26, size: 20),
                title: Text(historyItem, style: const TextStyle(color: Colors.black87, fontSize: 15)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 16),
                  onPressed: () => searchVM.deleteHistoryItem(historyItem),
                ),
                onTap: () {
                  // Khi ấn vào từ khóa lịch sử:
                  _searchController.text = historyItem; // Gán chữ lên thanh tìm kiếm
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: historyItem.length), // Đẩy con trỏ xuống cuối chữ
                  );
                  searchVM.onSearchQueryChanged(historyItem); // Kích hoạt tìm kiếm dữ liệu luôn
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('Gõ tên bác sĩ, chuyên khoa hoặc phòng khám...', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}