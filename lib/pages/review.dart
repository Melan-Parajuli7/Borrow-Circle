import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/review_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/core/validators.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/loan_model.dart';

/// Leave a review after the item was returned.
class ReviewPage extends StatefulWidget {
  final LoanModel loan;
  const ReviewPage({super.key, required this.loan});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _comment = TextEditingController();
  int _rating = 5;
  final Set<String> _tags = {};

  static const _tagOptions = ['Easy pickup', 'Great condition', 'Friendly'];
  static const _ratingText = ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final tooLong = Validators.maxLength(_comment.text, 500);
    if (tooLong != null) {
      showSnack(context, tooLong, isError: true);
      return;
    }

    // chips + typed text become one comment
    final parts = <String>[..._tags];
    if (_comment.text.trim().isNotEmpty) parts.add(_comment.text.trim());
    final comment = parts.join('. ');

    final ctrl = context.read<ReviewController>();
    final ok = await ctrl.createReview(
      loanId: widget.loan.id,
      rating: _rating,
      comment: comment.length > 500 ? comment.substring(0, 500) : comment,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      showSnack(context, 'Thanks! Your review was published.');
    } else {
      showSnack(context, ctrl.actionError ?? 'Could not publish the review', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final me = context.watch<AuthController>().user?.id;
    final iBorrowed = me == loan.borrowerId;
    final otherName = iBorrowed ? loan.ownerName : loan.borrowerName;
    final busy = context.watch<ReviewController>().isBusy;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Leave a review'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    Container(
                      height: 110,
                      width: 110,
                      decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                      child: const Icon(Icons.done_all, color: AppColors.primary, size: 46),
                    ),
                    const SizedBox(height: 12),
                    const PillTag(text: 'Returned'),
                    const SizedBox(height: 14),
                    const Text('Thanks for sharing.',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    const Text(
                      'Your review helps students borrow confidently.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          NetImage(url: AppStatic.imageUrl(loan.itemImage), width: 76, height: 76, radius: 14),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loan.itemTitle,
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text('Completed \u00b7 ${Fmt.range(loan.startDate, loan.endDate)}',
                                    style: const TextStyle(color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      iBorrowed ? 'How was borrowing from $otherName?' : 'How was lending to $otherName?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    StarRating(rating: _rating, size: 46, onChanged: (v) => setState(() => _rating = v)),
                    const SizedBox(height: 10),
                    Text('$_rating out of 5 \u00b7 ${_ratingText[_rating]}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _tagOptions)
                          FilterChip(
                            label: Text(t),
                            selected: _tags.contains(t),
                            onSelected: (v) => setState(() => v ? _tags.add(t) : _tags.remove(t)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppTextField(
                        controller: _comment,
                        label: 'Your review',
                        hint: 'The item was in great condition and pickup was super easy.',
                        maxLines: 3,
                        maxLength: 500,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe later')),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                text: 'Publish Review',
                icon: Icons.send_outlined,
                isLoading: busy,
                onPressed: _publish,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
