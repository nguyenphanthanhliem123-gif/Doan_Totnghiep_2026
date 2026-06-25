import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_list_screen.dart';
import '../constants/ui_constants.dart';
import '../viewmodels/specialty_viewmodel.dart';
import '../Models/specialtyModel.dart'; 

class SpecialtyListScreen extends StatefulWidget {
  const SpecialtyListScreen({super.key});

  @override
  State<SpecialtyListScreen> createState() => _SpecialtyListScreenState();
}

class _SpecialtyListScreenState extends State<SpecialtyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyViewModel>().loadAllSpecialties();
    });
  }

  // Hàm chuyển đổi chuỗi từ DB thành Icon thực tế
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'tooth':
        return Icons.clean_hands_rounded; 
      case 'spa':
        return Icons.spa_rounded; 
      case 'visibility':
        return Icons.visibility_rounded; 
      case 'hearing':
        return Icons.hearing_rounded; 
      default:
        return Icons.local_hospital_rounded; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialtyVM = context.watch<SpecialtyViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Danh Sách Chuyên Khoa',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: specialtyVM.isLoading
        ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
        : (specialtyVM.listSpecialty == null || specialtyVM.listSpecialty!.isEmpty)
            ? const Center(child: Text("Không có dữ liệu chuyên khoa", style: TextStyle(color: Colors.grey)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: specialtyVM.listSpecialty!.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16), // Khoảng cách giữa các thẻ
                itemBuilder: (context, index) {
                  final specialty = specialtyVM.listSpecialty![index];
                  
                  return InkWell(
                    onTap: () {
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DoctorListScreen(
                            specialtyId: specialty.id,
                            specialtyName: specialty.name,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // 1. Icon bên trái
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconData(specialty.image),
                              color: kPrimaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // 2. Nội dung ở giữa
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  specialty.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  specialty.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // 3. Nút mũi tên điều hướng bên phải
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}