import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ticket_model.dart';
import '../../ticket/bloc/ticket_bloc.dart';
import '../../ticket/bloc/ticket_event.dart';

class UserRatingModal extends StatefulWidget {
  final TicketModel ticket;
  final VoidCallback? onSubmitted;

  const UserRatingModal({super.key, required this.ticket, this.onSubmitted});

  static Future<void> show(BuildContext context, TicketModel ticket, {VoidCallback? onSubmitted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserRatingModal(ticket: ticket, onSubmitted: onSubmitted),
    );
  }

  @override
  State<UserRatingModal> createState() => _UserRatingModalState();
}

class _UserRatingModalState extends State<UserRatingModal> {
  int _selectedStars = 5;
  final _reviewController = TextEditingController();
  final List<String> _selectedChips = [];
  bool _isSubmitting = false;

  final List<String> _quickTags = [
    'Datang Cepat',
    'Pekerjaan Rapi',
    'Sopan & Ramah',
    'Alat Lengkap',
    'Harga Transparan',
    'Sangat Ahli',
  ];

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Sangat Kecewa 😞';
      case 2:
        return 'Kurang Memuaskan 😕';
      case 3:
        return 'Cukup Baik 🙂';
      case 4:
        return 'Sangat Bagus & Puas 😊';
      case 5:
        return 'Luar Biasa Sempurna! 🤩';
      default:
        return '';
    }
  }

  void _submitReview() async {
    setState(() => _isSubmitting = true);

    String finalReview = _reviewController.text.trim();
    if (_selectedChips.isNotEmpty) {
      final chipText = '[${_selectedChips.join(', ')}]';
      finalReview = finalReview.isEmpty ? chipText : '$chipText $finalReview';
    }

    context.read<TicketBloc>().add(
          SubmitRatingReviewRequestedEvent(
            ticketId: widget.ticket.id,
            stars: _selectedStars,
            review: finalReview.isEmpty ? 'Pelayanan sangat memuaskan!' : finalReview,
          ),
        );

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.pop(context);
    widget.onSubmitted?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Terima kasih atas ulasan & penilaian bintang Anda!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tukangName = widget.ticket.selectedTukangName ?? 'Mitra Teknisi';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Beri Penilaian Servis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Bagaimana pengalaman kerja bersama $tukangName?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Star Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  final isSelected = starVal <= _selectedStars;
                  return IconButton(
                    iconSize: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => setState(() => _selectedStars = starVal),
                    icon: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected ? Colors.amber.shade500 : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _getStarLabel(_selectedStars),
                  key: ValueKey(_selectedStars),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Tag Chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hal yang Anda sukai dari teknisi:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTags.map((tag) {
                  final isSelected = _selectedChips.contains(tag);
                  return FilterChip(
                    label: Text(tag, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : AppColors.textDark)),
                    selected: isSelected,
                    backgroundColor: const Color(0xFFF8FAFC),
                    selectedColor: const Color(0xFFEFF6FF),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedChips.add(tag);
                        } else {
                          _selectedChips.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Text Review Field
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan ulasan tambahan (opsional)...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Nanti Saja', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Kirim Penilaian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
