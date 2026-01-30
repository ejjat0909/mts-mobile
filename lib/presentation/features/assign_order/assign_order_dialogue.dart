import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mts/app/theme/app_theme.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/core/utils/log_utils.dart';
import 'package:mts/core/utils/navigation_utils.dart';
import 'package:mts/data/models/sale/sale_model.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/widgets/button_tertiary.dart';
import 'package:mts/presentation/common/widgets/my_text_form_field.dart';
import 'package:mts/presentation/common/widgets/skeleton_card.dart';
import 'package:mts/presentation/common/widgets/space.dart';
import 'package:mts/presentation/features/assign_order/components/assign_order_item.dart';
import 'package:mts/providers/sale/sale_providers.dart';
import 'package:mts/providers/user/user_providers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AssignOrderDialogue extends ConsumerStatefulWidget {
  final SaleModel currSaleModel;
  const AssignOrderDialogue({super.key, required this.currSaleModel});

  @override
  ConsumerState<AssignOrderDialogue> createState() =>
      _AssignOrderDialogueState();
}

class _AssignOrderDialogueState extends ConsumerState<AssignOrderDialogue>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  UserModel? _selectedUser;
  final _searchController = TextEditingController();

  List<UserModel> listUser = [];
  List<UserModel> filteredUsers = [];
  UserModel? currUserOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getData();
    });

    _searchController.addListener(_filterStaff);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.removeListener(_filterStaff);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    prints('getData');
    final userNotifier = ref.read(userProvider.notifier);
    listUser = userNotifier.getUserList;
    filteredUsers = List.from(listUser);

    if (widget.currSaleModel.id != null &&
        widget.currSaleModel.staffId != null) {
      final userModel = await userNotifier.getUserModelFromStaffId(
        widget.currSaleModel.staffId!,
      );
      if (userModel?.id != null) {
        currUserOrder = userModel;
        _selectedUser = currUserOrder;
      }
    }
    setState(() {});
  }

  void _filterStaff() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(listUser); // Reset to original list
      } else {
        filteredUsers =
            listUser.where((user) {
              final name = user.name?.toLowerCase() ?? '';
              final email = user.email?.toLowerCase() ?? '';
              final phone = user.phoneNo?.toLowerCase() ?? '';

              return name.contains(query) ||
                  email.contains(query) ||
                  phone.contains(query);
            }).toList();
      }
      prints("filteredUsers: $filteredUsers");
    });
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.of(context).size.height;
    double availableWidth = MediaQuery.of(context).size.width;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          minHeight: availableHeight,
          maxWidth: availableWidth / 2,
          minWidth: availableWidth / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            10.heightBox,
            AppBar(
              elevation: 0,
              backgroundColor: white,
              title: Row(
                children: [
                  Text('assignOrder'.tr(), style: AppTheme.h1TextStyle()),
                  const Expanded(flex: 2, child: SizedBox()),
                  Expanded(
                    flex: 1,
                    child: ButtonTertiary(
                      text: 'assign'.tr(),
                      icon: FontAwesomeIcons.download,
                      onPressed: () async {
                        await Future.delayed(const Duration(milliseconds: 200));

                        NavigationUtils.pop(context);

                        if (_selectedUser?.id != null &&
                            widget.currSaleModel.id != null) {
                          await ref
                              .read(saleProvider.notifier)
                              .onAssignOrder(
                                widget.currSaleModel,
                                _selectedUser!,
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                icon: Icon(Icons.close, color: canvasColor),
                onPressed: () {
                  NavigationUtils.pop(context);
                },
              ),
            ),
            10.heightBox,
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: MyTextFormField(
                controller: _searchController,
                labelText: 'searchStaff'.tr(),
                hintText: 'searchStaff'.tr(),
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            15.heightBox,
            // User list with animation
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _animationController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child:
                    listUser.isEmpty
                        ? SkeletonCard()
                        : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          // padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final isSelected = _selectedUser?.id == user.id;

                            // Create a staggered animation effect
                            final itemAnimation = Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  index / filteredUsers.length * 0.7,
                                  (index + 1) / filteredUsers.length * 0.7 +
                                      0.3,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            );

                            return AssignOrderItem(
                              user: user,
                              isSelected: isSelected,
                              animation: itemAnimation,
                              onTap: () {
                                setState(() {
                                  _selectedUser = user;
                                });
                              },
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
