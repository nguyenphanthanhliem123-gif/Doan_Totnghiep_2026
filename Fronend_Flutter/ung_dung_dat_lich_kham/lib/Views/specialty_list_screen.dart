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
      backgroundColor: const Color(0xFFF8FAFC),
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
          : specialtyVM.errorMessage.isNotEmpty
              ? Center(child: Text(specialtyVM.errorMessage, style: const TextStyle(color: Colors.red)))
              : specialtyVM.listSpecialty == null || specialtyVM.listSpecialty!.isEmpty
                  ? const Center(child: Text('Không tìm thấy chuyên khoa nào.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: specialtyVM.listSpecialty!.length,
                      itemBuilder: (context, index) {
                        final specialty = specialtyVM.listSpecialty![index];
                        return _buildSpecialtyCard(specialty);
                      },
                    ),
    );
  }

  Widget _buildSpecialtyCard(SpecialtyModel specialty) {
    return InkWell(
      onTap: () {
        if(!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => DoctorListScreen(specialtyId: specialty.id, specialtyName: specialty.name,))
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            // Vòng tròn chứa Icon chuyên khoa
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(specialty.image), 
                color: kPrimaryColor, 
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            // Tên chuyên khoa
            Text(
              specialty.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
            ),
            const SizedBox(height: 4),
            // Mô tả ngắn chuyên khoa
            Text(
              specialty.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: kGreyTextColor, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}