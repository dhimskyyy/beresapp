import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_saved_address.dart';
import 'user_add_edit_address_page.dart';

class UserAddressListPage extends StatefulWidget {
  final List<UserSavedAddress> initialAddresses;
  final String activeAddressId;
  final String userName;
  final String userPhone;
  final Function(List<UserSavedAddress>, String activeId) onAddressesChanged;

  const UserAddressListPage({
    super.key,
    required this.initialAddresses,
    required this.activeAddressId,
    required this.userName,
    required this.userPhone,
    required this.onAddressesChanged,
  });

  @override
  State<UserAddressListPage> createState() => _UserAddressListPageState();
}

class _UserAddressListPageState extends State<UserAddressListPage> {
  late List<UserSavedAddress> _addresses;
  late String _activeId;

  @override
  void initState() {
    super.initState();
    _addresses = List.from(widget.initialAddresses);
    _activeId = widget.activeAddressId;
  }

  void _notifyParent() {
    widget.onAddressesChanged(_addresses, _activeId);
  }

  Future<void> _navigateToAddAddress() async {
    final newAddress = await Navigator.push<UserSavedAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => UserAddEditAddressPage(
          defaultRecipientName: widget.userName,
          defaultPhone: widget.userPhone,
        ),
      ),
    );

    if (newAddress != null) {
      setState(() {
        if (newAddress.isPrimary) {
          _addresses = _addresses.map((a) => a.copyWith(isPrimary: false)).toList();
          _activeId = newAddress.id;
        }
        _addresses.add(newAddress);
      });
      _notifyParent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat "${newAddress.label}" berhasil ditambahkan!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _navigateToEditAddress(UserSavedAddress address) async {
    final updatedAddress = await Navigator.push<UserSavedAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => UserAddEditAddressPage(
          initialAddress: address,
          defaultRecipientName: widget.userName,
          defaultPhone: widget.userPhone,
        ),
      ),
    );

    if (updatedAddress != null) {
      setState(() {
        final index = _addresses.indexWhere((a) => a.id == updatedAddress.id);
        if (index != -1) {
          if (updatedAddress.isPrimary) {
            _addresses = _addresses.map((a) => a.copyWith(isPrimary: false)).toList();
            _activeId = updatedAddress.id;
          }
          _addresses[index] = updatedAddress;
        }
      });
      _notifyParent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alamat "${updatedAddress.label}" berhasil diperbarui!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _confirmDeleteAddress(UserSavedAddress address) {
    if (_addresses.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus memiliki minimal satu alamat tersimpan.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (diagCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Alamat?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menghapus alamat "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(diagCtx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(diagCtx);
              setState(() {
                _addresses.removeWhere((a) => a.id == address.id);
                if (_activeId == address.id) {
                  _activeId = _addresses.first.id;
                }
              });
              _notifyParent();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alamat berhasil dihapus.'), backgroundColor: AppColors.primary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            child: const Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Alamat Tersimpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Informative Top Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFEFF6FF),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pilih alamat aktif untuk kedatangan tukang. Anda dapat menambah, mengubah titik lokasi peta, atau menghapus alamat.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          // Address List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                final isSelected = addr.id == _activeId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => _activeId = addr.id);
                        _notifyParent();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Alamat aktif diubah ke: ${addr.label}'),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Tag & Selection Check
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primary : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        addr.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    if (addr.isPrimary) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.successGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('Utama', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                                      ),
                                    ],
                                  ],
                                ),
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                  size: 22,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Recipient & Phone
                            Text(
                              '${addr.recipientName} • ${addr.phone}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),

                            // Full Address
                            Text(
                              addr.fullAddress,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35),
                            ),

                            // Note / Benchmark
                            if (addr.note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      addr.note,
                                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),

                            // Actions: Edit and Delete Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _navigateToEditAddress(addr),
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                  label: const Text('Ubah Alamat', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmDeleteAddress(addr),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.dangerRed),
                                  label: const Text('Hapus', style: TextStyle(fontSize: 12, color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action: Add New Address
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddAddress,
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
              label: const Text('Tambah Alamat Baru dengan Peta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
