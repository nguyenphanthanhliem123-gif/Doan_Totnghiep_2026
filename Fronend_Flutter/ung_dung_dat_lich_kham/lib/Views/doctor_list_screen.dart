import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ung_dung_dat_lich_kham/Views/doctor_detail_screen.dart';
import '../Constants/ui_constants.dart'; // 🌟 Đồng bộ UI Constants
import '../viewmodels/doctor_viewmodel.dart';
import '../Models/doctor_model.dart';

class DoctorListScreen extends StatefulWidget {
  final int? specialtyId;
  final String? specialtyName;

  const DoctorListScreen({super.key, this.specialtyId, this.specialtyName});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  // ĐÃ XOÁ: Biến selectedLocation
  double minPrice = 0;
  double maxPrice = 1000000;
  double? selectedRating;
  DateTime? selectedDate;

  String selectedSort = 'default';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorViewModel>().loadDoctors(specialtyId: widget.specialtyId);
    });
  }

  // ĐÃ XOÁ: Hàm _determinePosition sử dụng GPS Geolocator

  @override
  Widget build(BuildContext context) {
    final doctorVM = context.watch<DoctorViewModel>();

    return Scaffold(
      backgroundColor: kLightCyanBg2, // 🌟 Dùng nền xanh siêu nhạt cho chuẩn
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.specialtyName != null ? 'Bác sĩ ${widget.specialtyName}' : 'Danh Sách Bác Sĩ',
          style: kHeaderTextStyle, // 🌟 Style chuẩn
        ),
      ),
      body: Column(
        children: [
          // 🌟 THANH SẮP XẾP & LỌC 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 10), // Lề 20
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sort_rounded, color: kGreyTextColor, size: 20),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSort,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: const TextStyle(fontSize: 14, color: kTextColor, fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(value: 'default', child: Text('Mới nhất')),
                          DropdownMenuItem(value: 'rating_desc', child: Text('Đánh giá cao nhất')),
                          DropdownMenuItem(value: 'price_asc', child: Text('Giá thấp nhất')),
                          // ĐÃ XOÁ: DropdownMenuItem 'distance_asc' (Gần tôi nhất)
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              selectedSort = value;
                              
                              if (value == 'default') {
                                minPrice = 0;
                                maxPrice = 1000000;
                                selectedRating = null;
                                selectedDate = null;
                              }
                            });
                            String? formattedDate;
                            if(selectedDate != null) {
                              formattedDate = "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                            }

                            double? apiMinPrice = minPrice == 0 ? null : minPrice;
                            double? apiMaxPrice = maxPrice == 1000000 ? null : maxPrice;

                            context.read<DoctorViewModel>().loadDoctors(
                              specialtyId: widget.specialtyId,
                              sortBy: value == 'default' ? null : value,
                              minPrice: apiMinPrice,
                              maxPrice: apiMaxPrice,
                              minRating: selectedRating,
                              availableDate: formattedDate,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                
                TextButton.icon(
                  onPressed: () => _showFilterBottomSheet(context),
                  icon: const Icon(Icons.filter_alt_outlined, size: 18, color: kPrimaryColor),
                  label: const Text('Lọc', style: TextStyle(color: kPrimaryColor)),
                )
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1, color: kBorderCyan), // Màu viền chuẩn

          // 🌟 DANH SÁCH BÁC SĨ
          Expanded(
            child: doctorVM.isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : doctorVM.errorMessage.isNotEmpty
                    ? Center(child: Text(doctorVM.errorMessage, style: const TextStyle(color: Colors.red)))
                    : doctorVM.listDoctor == null || doctorVM.listDoctor!.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(kDefaultPadding), // Padding 20
                            itemCount: doctorVM.listDoctor!.length,
                            itemBuilder: (context, index) {
                              return _buildDoctorCard(doctorVM.listDoctor![index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: kSpacingSmall),
          const Text('Chưa có bác sĩ nào trong chuyên khoa này.', style: TextStyle(color: kGreyTextColor)),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
    return InkWell(
      onTap: () {
        if(!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: doctor.id,))
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: kSpacingSmall),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kBorderRadiusLarge), // Bo góc 20 chuẩn
          border: Border.all(color: kBorderCyan, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(kBorderRadiusSmall), // Bo 12
              child: Container(
                width: 85,
                height: 100,
                color: kLightCyanBg1, // Màu nền xanh nhạt
                child: doctor.avatar != null && doctor.avatar!.isNotEmpty
                    ? Image.network(doctor.avatar!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: kPrimaryColor, size: 40))
                    : const Icon(Icons.person, color: kPrimaryColor, size: 40),
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${doctor.degree ?? "BS."} ${doctor.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  Text(
                    doctor.specialtyName,
                    style: const TextStyle(fontSize: 13, color: kPrimaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.work_history_rounded, color: kGreyTextColor, size: 16),
                      const SizedBox(width: 5),
                      Text('${doctor.experienceYears} năm kinh nghiệm', style: const TextStyle(fontSize: 13, color: kGreyTextColor)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  if (doctor.ratingSummary != null && doctor.ratingSummary!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.thumb_up_alt_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            doctor.ratingSummary!,
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kBorderRadiusLarge))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: kDefaultPadding, right: kDefaultPadding, top: kDefaultPadding
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lọc Bác Sĩ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),

                  // ĐÃ XOÁ: Dropdown lọc theo "Khu vực"

                  Text('Khoảng giá: ${(minPrice/1000).toStringAsFixed(0)}k - ${(maxPrice/1000).toStringAsFixed(0)}k', style: const TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: RangeValues(minPrice, maxPrice),
                    min: 0,
                    max: 2000000,
                    divisions: 20,
                    activeColor: kPrimaryColor,
                    labels: RangeLabels('${minPrice.toInt()}', '${maxPrice.toInt()}'),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        minPrice = values.start;
                        maxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: kSpacingLarge),

                  const Text('Đánh giá tối thiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 10,
                    children: [3, 4, 5].map((star) {
                      return ChoiceChip(
                        label: Text('$star+ Sao'),
                        selected: selectedRating == star.toDouble(),
                        selectedColor: kLightCyanBg1,
                        onSelected: (selected) {
                          setModalState(() => selectedRating = selected ? star.toDouble() : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: kSpacingLarge),

                  const Text('Ngày khám', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(selectedDate == null ? 'Chọn ngày' : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                    trailing: const Icon(Icons.calendar_month, color: kPrimaryColor),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: kPrimaryColor),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setModalState(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: kSpacingLarge),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            minPrice = 0; maxPrice = 1000000;
                            selectedRating = null; selectedDate = null;
                            Navigator.pop(context); 
                            context.read<DoctorViewModel>().loadDoctors(specialtyId: widget.specialtyId);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kGreyTextColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                          ),
                          child: const Text('Xóa lọc', style: TextStyle(color: kGreyTextColor)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kBorderRadiusSmall)),
                          ),
                          onPressed: () {
                            Navigator.pop(context); 
                            String? formattedDate = selectedDate != null 
                                ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}" 
                                : null;

                            double? apiMinPrice = minPrice == 0 ? null : minPrice;
                            double? apiMaxPrice = maxPrice == 1000000 ? null : maxPrice;

                            context.read<DoctorViewModel>().loadDoctors(
                              specialtyId: widget.specialtyId,
                              minPrice: apiMinPrice,
                              maxPrice: apiMaxPrice,
                              minRating: selectedRating,
                              availableDate: formattedDate,
                            );
                          },
                          child: const Text('Áp dụng', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}