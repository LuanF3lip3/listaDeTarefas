import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp( const MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ),
  );
}

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

List _toDoList = [];

late Map _lastRemoved;
late int _lastRemovedPos;
  
TextEditingController textToDo = TextEditingController();
// final text = TextEditingController();

@override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
      _toDoList = jsonDecode(data);
      });
    });
  }

void _addToDo() {
  setState(() {
    Map<String, dynamic> newToDo = {};
    newToDo["title"] = textToDo.text;
    textToDo.clear();
    newToDo["ok"] = false;
    _toDoList.add(newToDo);
    _saveData();
    });
  }

    Future<File> _getFile() async{
final directory = await getApplicationDocumentsDirectory();
return File("${directory.path}/data.json"); 
}

Future<File> _saveData() async{
String data = json.encode(_toDoList);
final file = await _getFile();
return file.writeAsString(data);
}

Future<String> _readData() async{
try{
final file = await _getFile();
return file.readAsString();
}catch (e) {
return "";
}
}

Future<void> _refresh() async{
  await Future.delayed(const Duration(milliseconds: 1500 ));
  setState(() {
_toDoList.sort((a, b) {
  if(a["ok"] && !b["ok"]) {
    return 1;
  } else if(b["ok"] && !a["ok"]) {
    return -1;
  }else {
    return 0;
  }
  });
    _saveData();
},
);
}

Widget buildItem  (context, index){
 return Dismissible(key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
 background: Container(
   color: Colors.red,
   child: const Align(
     alignment: Alignment(-0.9, 0.0),
     child: Icon(Icons.delete, color: Colors.white,),
   ),
 ),
 direction: DismissDirection.startToEnd,
  child: CheckboxListTile(
title: Text(_toDoList[index]["title"]),
value: _toDoList[index]["ok"],
onChanged: (c) {
setState(() {
_toDoList[index]["ok"] = c;
_saveData();
});
},
secondary: CircleAvatar(child: Icon(_toDoList[index]["ok"]?
Icons.check: Icons.error),
),
),
onDismissed: (direction) {
  setState(() {
  _lastRemoved = Map.from(_toDoList[index]);
  _lastRemovedPos = index;
  _toDoList.removeAt(index);

    _saveData();
  });

  final snack = SnackBar(
    content: Text("Tarefa \"${_lastRemoved["title"]}\" foi deletada con sucesso!!!" ),
    action: SnackBarAction(label: "desfazer",
    onPressed: (){
      setState(() {
      _toDoList.insert(_lastRemovedPos, _lastRemoved);
      });
    }
  ),
  duration: const Duration(seconds: 3),
  );
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snack);
},
);

}
 

  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(
       title: const Text("Lista de Terefas"),
       centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1 ,7, 1),
            child: Row(
              children: [
                 Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: "Nova Tarefa"
                    ),
                    controller: textToDo,
                    onChanged: (value) {
                      setState(() {
                        textToDo.text = value;
                      });
                    },
                  ),
                ),
                ElevatedButton(onPressed: textToDo.text.isEmpty ? null : _addToDo,
                child: const Text("Add"))
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: _toDoList.length,
                padding: const EdgeInsets.only(top: 10),
                itemBuilder: buildItem,
                ),
            ),
          )
        ],
      ),
    );
  }
}
