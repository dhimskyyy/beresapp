import 'package:flutter/material.dart';
import 'app_colors.dart';

class ServiceCategoryItem {
  final String id;
  final String name;
  final IconData icon;
  final Color backgroundColor;
  final String description;

  const ServiceCategoryItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.backgroundColor,
    required this.description,
  });
}

class ServiceCategories {
  static const List<ServiceCategoryItem> all = [
    ServiceCategoryItem(
      id: 'ac',
      name: 'AC',
      icon: Icons.ac_unit,
      backgroundColor: AppColors.bgAC,
      description: 'Cuci AC, perbaikan kompresor, isi freon & instalasi',
    ),
    ServiceCategoryItem(
      id: 'cleaning',
      name: 'Cleaning',
      icon: Icons.cleaning_services,
      backgroundColor: AppColors.bgCleaning,
      description: 'Pembersihan rumah, sedot tungau, cuci toren air',
    ),
    ServiceCategoryItem(
      id: 'elektronik',
      name: 'Elektronik',
      icon: Icons.devices,
      backgroundColor: AppColors.bgElektronik,
      description: 'Servis mesin cuci, kulkas, TV, dispenser & microwave',
    ),
    ServiceCategoryItem(
      id: 'las',
      name: 'Las',
      icon: Icons.precision_manufacturing,
      backgroundColor: AppColors.bgLas,
      description: 'Pembuatan & perbaikan pagar, kanopi, teralis, gerbang',
    ),
    ServiceCategoryItem(
      id: 'bangunan',
      name: 'Bangunan',
      icon: Icons.foundation,
      backgroundColor: AppColors.bgBangunan,
      description: 'Cat dinding, keramik, renovasi & perbaikan atap bocor',
    ),
    ServiceCategoryItem(
      id: 'besi_baja',
      name: 'Besi & Baja',
      icon: Icons.shield,
      backgroundColor: AppColors.bgBesiBaja,
      description: 'Rangka baja ringan, kanopi baja, konstruksi besi',
    ),
    ServiceCategoryItem(
      id: 'bengkel_motor',
      name: 'Bengkel Motor',
      icon: Icons.two_wheeler,
      backgroundColor: AppColors.bgBengkelMotor,
      description: 'Servis berkala, tambal/ganti ban darurat, aki drop',
    ),
    ServiceCategoryItem(
      id: 'bengkel_mobil',
      name: 'Bengkel Mobil',
      icon: Icons.directions_car,
      backgroundColor: AppColors.bgBengkelMobil,
      description: 'Servis panggilan darurat, jumper aki, tune-up ringan',
    ),
    ServiceCategoryItem(
      id: 'pengrajin_kayu',
      name: 'Pengrajin Kayu',
      icon: Icons.carpenter,
      backgroundColor: AppColors.bgKayu,
      description: 'Kitchen set, reparasi mebel, kusen, pintu & lemari',
    ),
    ServiceCategoryItem(
      id: 'plumbing',
      name: 'Plumbing',
      icon: Icons.plumbing,
      backgroundColor: AppColors.bgPlumbing,
      description: 'Pipa bocor/mampet, instalasi baru, servis pompa air',
    ),
  ];

  static ServiceCategoryItem? findById(String id) {
    try {
      return all.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }

  static IconData getIconForCategory(String id) {
    return findById(id)?.icon ?? Icons.build_rounded;
  }
}

