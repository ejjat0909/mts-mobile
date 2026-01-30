import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mts/app/theme/text_styles.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/user/user_model.dart';
import 'package:mts/presentation/common/widgets/space.dart';

class AssignOrderItem extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final Animation<double> animation;
  final VoidCallback onTap;

  const AssignOrderItem({
    super.key,
    required this.user,
    required this.isSelected,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
          elevation: 0,
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? kPrimaryColor : kTextGray,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                    child: Text(
                      user.name?.isNotEmpty == true
                          ? user.name![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  16.widthBox,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'null',
                          style: textStyleMedium(color: kBlackColor),
                        ),
                        if (user.email != null && user.email!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              user.email!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        if (user.phoneNo != null && user.phoneNo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              user.phoneNo!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(FontAwesomeIcons.circleCheck, color: kPrimaryColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
