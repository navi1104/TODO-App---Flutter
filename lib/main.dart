import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

TextEditingController taskController = new TextEditingController();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;
  void addfunc() {
    Navigator.pop(context);
    db
        .collection('tasks')
        .add({"task": taskController.text, "time": DateTime.now()});
    taskController.clear();
  }

  void updfunc(ds) {
    Navigator.pop(context);
    db.collection('tasks').doc(ds.id).update({'task': taskController.text});
    taskController.clear();
  }

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  void showdialog(isUpdate, ds) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(isUpdate ? "Update Task" : "Add Task"),
            content: Form(
                child: Column(
              children: [
                TextFormField(
                    key: formKey,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                    controller: taskController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Task Title",
                    )),
                ElevatedButton(
                    onPressed: isUpdate
                        ? () {
                            updfunc(ds);
                          }
                        : addfunc,
                    child: Text(isUpdate ? "Update Task" : "Add Task"))
              ],
            )),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TODO App')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showdialog(false, null);
        },
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('tasks').orderBy("time").snapshots(),
        builder: ((context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: ((context, index) {
                  DocumentSnapshot ds = snapshot.data!.docs[index];
                  return Container(
                    child: Card(
                      child: ListTile(
                        title: Text(ds['task']),
                        onTap: (() {
                          //update

                          showdialog(true, ds);
                        }),
                        onLongPress: () {
                          //delete
                          Alert(
                            context: context,
                            type: AlertType.warning,
                            title: "ALERT!",
                            desc: "Are you sure you want to DELETE this task?",
                            buttons: [
                              DialogButton(
                                child: Text(
                                  "YES",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                onPressed: () {
                                  db.collection('tasks').doc(ds.id).delete();
                                  Navigator.pop(context);
                                },
                                color: Color.fromRGBO(0, 179, 134, 1.0),
                              ),
                              DialogButton(
                                child: Text(
                                  "NO",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                onPressed: () => Navigator.pop(context),
                                gradient: LinearGradient(colors: [
                                  Color.fromRGBO(116, 116, 191, 1.0),
                                  Color.fromRGBO(52, 138, 199, 1.0)
                                ]),
                              )
                            ],
                          ).show();
                        },
                      ),
                    ),
                  );
                }));
          }
          if (snapshot.hasError) {
            return Text("Oops! Something went wrong ");
          }
          return Center(child: CircularProgressIndicator());
        }),
      ),
    );
  }
}
