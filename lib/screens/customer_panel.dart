import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:t2t_flutter_prototype/models/consumer_driver_info.dart';

const tLogOut = 'Log Out';
const tGiveFeedback = 'TODO: Give Feedback';
const tSettings = 'TODO: Settings';
const tCallProvider = 'Call Provider';
const tOmgYourACustomer = "OMG You're a Customer!";
const tYouAreHere = 'You are here';
const tChooseYourDestination = 'Choose your Destination';
const tCorrectAddress = 'Is this address correct?';
const tCancel = 'Cancel';
const tConfirm = 'Confirm';
const tCancelActiveRequest = 'Cancel Active Request?';
const tNevermind = 'Nevermind';
const tProviderOnTheWay = 'Provider on the way!';
const tProvider = 'Provider';
const tYourLocation = 'Your Location';
const tProviderTowing = 'The Provider is Towing';
const tTotalDistance = 'Total Distance';
const tDestination = 'Destination';
const tDetails = 'Details';
const tDriverIs = 'Your driver is : ';
const tProviderCompany = 'Provider Company';

const MILE_TO_KM_RATIO = 0.621371;

final textInputSyle = TextStyle(fontSize: 24, color: Colors.blueGrey);
final textInputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(6));

final nop = () => null;

class CustomerPanel extends StatelessWidget {
  CustomerPanel({ Key? key }) : super(key: key);


  @override
  Widget build(BuildContext screenContext) {
    // final driverInfo = screenContext.read<ScheduleCustomerBloc>().state.driverInfo;

    // These variables are not yet defined in the model, using as placeholders
    final driverInfo = ConsumerDriverInfo('John Smith', 'Some Trucks, LLC');
    final driverCompanyPhone = '1-800-511-9112';
    final driverPhone = '531-222-3412';
    final driverImage = 'assets/images/lol.jpeg';

    final driverInfoNotProvided = driverInfo == null;
    final driverName = driverInfoNotProvided ? '' : driverInfo!.name;
    final driverCompany = driverInfoNotProvided ? '' : driverInfo!.companyName;


    if (driverInfoNotProvided) {
      // "The correct way" to show an empty widget - official Material codebase uses this.
      return SizedBox.shrink();
    }

    return
      SlidingUpPanel(
        // TODO: Card https://trello.com/b/xWWKTN7r/prototype
        // TODO: Firestore: https://console.firebase.google.com/u/1/project/tow-2-tow-prototype/firestore/data/~2Frequest~2FLZsgjvO9tD9UpzMVGfeV
        // TODO: Slider API: https://pub.dev/packages/sliding_up_panel
        // TODO: Bucket stuff https://console.cloud.google.com/storage/browser/t2t_business_images;tab=objects?authuser=1&project=tow-2-tow-prototype-325219&prefix=&forceOnObjectsSortingFiltering=false
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        minHeight: 60,
        backdropTapClosesPanel: true,
        panel: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0
          ),
          child: Column(
            children: [
              Text(
                tDetails,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Divider(
                color: Colors.black,
                thickness: 2,
              ),
              Container(
                alignment: Alignment.center,
                child: Text(
                  driverCompany,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: Text(
                  driverCompanyPhone,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tDriverIs,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                ),
              ),
              Container(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: AssetImage(driverImage),
                        ),
                      ),
                    ),
                    Text(
                      driverName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    // Display Image
                  ],
                ),
              ),
              Container(
                height: 15,
                width: 200,
                child:Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      driverPhone,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        )
    );
  }
}
