import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main()=>runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  TextEditingController controller1;
  TextEditingController controller2;
  TextEditingController controller3;
  final formKey = GlobalKey<FormState>();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller1 = TextEditingController();
    controller2 = TextEditingController();
    controller3 = TextEditingController();


    var android = AndroidInitializationSettings("mipmap/ic_launcher");
    var ios = IOSInitializationSettings();
    var platform = InitializationSettings(android, ios);
    _plugin.initialize(platform);



    _firebaseMessaging.configure(
        onLaunch: (Map<String, dynamic> message){
          Scaffold.of(context).showSnackBar(SnackBar(content: Text("OnLaunche: $message")));
        },
        onMessage: (Map<String, dynamic> message){
          _handleNotification(message);
        } ,
        onResume: (Map<String, dynamic> message){
          Scaffold.of(context).showSnackBar(SnackBar(content: Text("OnResume: $message")));

        }
    );
  }


  _handleNotification(Map<String, dynamic> msg) async{
    var android = AndroidNotificationDetails( 'your channel id', 'your channel name', 'your channel description');
    var ios = IOSNotificationDetails();
    var platfrom = NotificationDetails(android, ios);
   await _plugin.show(0, "plain tite", "plain body", platfrom);
  }


  _getToken(String value) async{
    Firestore.instance.runTransaction((transaction) async{
      CollectionReference reference = Firestore.instance.collection("push_tokens");
      await reference.add({
        "devtoken" : value
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Firestor App"),),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10.0),
          child: Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: controller1,
                  autocorrect: false,
                  decoration: InputDecoration(
                      labelText: "username"
                  ),
                  validator: (str) =>
                  str.length < 6 ? 'User ame is not valid' : null,
                ),
                SizedBox(height: 5.0),
                TextFormField(
                  controller: controller2,
                  autocorrect: false,
                  decoration: InputDecoration(
                      labelText: 'email'
                  ),
                  validator: (str) =>
                  !str.contains('@') ? 'Not a valid email' : null,
                ),
                SizedBox(height: 5.0),
                TextFormField(
                  controller: controller3,
                  obscureText: true,
                  autocorrect: false,
                  decoration: InputDecoration(
                      labelText: "Password"
                  ),
                  validator: (str) =>
                  str.length < 8 ? 'Not a valid password' : null,
                ),
                SizedBox(height: 5.0,),
                RaisedButton(
                    child: Text("Send", style: TextStyle(color: Colors.white)),
                    color: Colors.purple,
                    onPressed: () {
                      var formState = formKey.currentState;
                      if(formState.validate()){
                        formState.save();
                        Firestore.instance.runTransaction((transaction) async {
                          CollectionReference refrence =  Firestore.instance
                              .collection('flutter_data');
                          await refrence.add({
                            "username": controller1.text,
                            "email": controller2.text,
                            "password": controller3.text
                          }).then((result){
                            controller1.clear();
                            controller2.clear();
                            controller3.clear();
                          });
                        });
                      }

                    }
                ),
                RaisedButton(
                  child: Text('Display data', style: TextStyle(color: Colors.white),),
                  color: Colors.purple,
                  onPressed: (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DisplayData()));
                  },
                ),
                RaisedButton(
                  child: Text("Get Tken"),
                  onPressed: (){
                    _firebaseMessaging.getToken().then((value){
                      _getToken(value);
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class DisplayData extends StatefulWidget{
  @override
  DisplayDataState createState() {
    return new DisplayDataState();
  }
}

class DisplayDataState extends State<DisplayData> {
  TextEditingController controller1;
  TextEditingController controller2;
  TextEditingController controller3;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller1 = TextEditingController();
    controller2 = TextEditingController();
    controller3 = TextEditingController();
  }
  @override
  Widget build(BuildContext context) {
    Widget _buildListTile(context, DocumentSnapshot document){
      return Container(
        padding: EdgeInsets.all(10.0),
        child: Card(
          elevation: 5.0,
          child: ListTile(
            title: Container(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Name : ${document['username']}'),
                  SizedBox(height: 5.0,),
                  Text('Email : ${document['email']}'),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(icon: Icon(Icons.delete), onPressed: (){
                      Firestore.instance.runTransaction((transaction) async{
                        DocumentSnapshot snapShot = await transaction.get(document.reference);
                        await transaction.delete(snapShot.reference);
                      });
                    }),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: IconButton(icon: Icon(Icons.update), onPressed: (){
                      return showDialog(
                          context: context,
                          builder: (context){
                            return AlertDialog(
                              contentPadding: EdgeInsets.all(10.0),
                              content: Container(
                                width: 200.0,
                                height: 200.0,
                                child: SingleChildScrollView(
                                  child: Form(
                                    key: formKey,
                                    child: Column(
                                      children: <Widget>[
                                        Text('Update form'),
                                        TextFormField(
                                          controller: controller1,
                                          autocorrect: false,
                                          decoration: InputDecoration(
                                              labelText: "username"
                                          ),
//                                      onSaved: (user) => _username = user,

                                        ),
                                        SizedBox(height: 5.0),
                                        TextFormField(
                                          controller: controller2,
                                          autocorrect: false,
                                          decoration: InputDecoration(
                                              labelText: 'email'
                                          ),
//                                      onSaved: (email) => _email = email,

                                        ),
                                        SizedBox(height: 5.0),
                                        TextFormField(
                                          controller: controller3,
                                          obscureText: true,
                                          autocorrect: false,
                                          decoration: InputDecoration(
                                              labelText: "Password"
                                          ),
//                                      onSaved: (pass) => _pass = pass,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text('Update'),
                                  onPressed: (){
                                    Firestore.instance.runTransaction((transaction) async{
                                      DocumentSnapshot snapshot = await transaction.get(document.reference);
                                      await transaction.update(snapshot.reference, {
                                        "username": controller1.text != "" ? controller1.text : snapshot.data['username'],
                                        "email": controller2.text != "" ? controller2.text : snapshot.data['email'],
                                        "password": controller3.text != "" ? controller3.text : snapshot.data['password']
                                      }).then((result){
                                        Navigator.pop(context);
                                      });
                                    });
                                  },
                                ),
                                FlatButton(
                                  child: Text('Cancel'),
                                  onPressed: (){
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          }
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('FireStore Data'),),
      body: Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('flutter_data').snapshots(),
          builder: (context, AsyncSnapshot snapshot) {
            return ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (context, index) => _buildListTile(context, snapshot.data.documents[index]),
            );
          } ,
        ),
      ),
    );
  }
}






//class Home extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(title: Text(''),
//      actions: <Widget>[
//        IconButton(
//          icon: Icon(Icons.add),
//          onPressed: () => Firestore.instance.runTransaction((transaction) async{
//            CollectionReference refrence = Firestore.instance.collection('flutter_data');
//            await refrence.add({
//              'title' : "", "editing" : false,
//            });
//          }),
//        )
//      ],),
//
//      body: StreamBuilder(
//        stream: Firestore.instance.collection('flutter_data').snapshots(),
//        builder: (context, AsyncSnapshot snapshot){
//          if(!snapshot.hasData) return Center(child: CircularProgressIndicator(),);
//          return FireStoreListview(documents: snapshot.data.documents,);
//        },
//      ),
//    );
//  }
//}
//
//class FireStoreListview extends StatelessWidget {
//  final List<DocumentSnapshot> documents;
//  FireStoreListview({this.documents});
//  @override
//  Widget build(BuildContext context) {
//    return ListView.builder(
//      itemCount: documents.length,
//      itemExtent: 50.0,
//      itemBuilder: (context, index){
//        return ListTile(
//          title: Container(
//            decoration: BoxDecoration(
//              borderRadius: BorderRadius.circular(5.0),
//              border: Border.all(color: Colors.grey),
//            ),
//              child: Row(
//                children: <Widget>[
//                  !documents[index].data["editing"] ?
//                  Text(documents[index].data['title'])
//                      :
//                      TextFormField(
//                        initialValue: documents[index].data["title"],
//                        onFieldSubmitted: (String item) {
//                          Firestore.instance.runTransaction((transaction) async{
//                            DocumentSnapshot frshsnapshot = await transaction.get(documents[index].reference);
//
//                            await transaction.update(frshsnapshot.reference,{
//                              'title' : item
//                            });
//
//                            await transaction.update(frshsnapshot.reference, {
//                              "editing" : !frshsnapshot["editing"]
//                            });
//                          });
//                        },
//                      ),
//                ],
//              )),
//          onTap: () => Firestore.instance.runTransaction((transaction) async{
//            DocumentSnapshot freshSnap = await transaction.get(documents[index].reference);
//            await transaction.update(freshSnap.reference, {
//              "editing" : !freshSnap["editing"]
//            });
//          }),
//        );
//      },
//    );
//  }
//}
