import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(
      home: Home(),
      debugShowCheckedModeBanner: false,
      title: "ListaYago",
    ));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //controlador para pegar os dados
  final _toDoController = TextEditingController();

  //criando uma lista para salvar as tarefas
  List _toDoList = [];

  //para saber qual foi excluido e poder desfazer
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;


  @override
  void initState() {
    super.initState();
    //como tem que aguardar, quando os dados chegar eles cairão na funcao dentrodo .then
    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  //adiciona o texto, adiciona o mapa na lista
  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodDo = Map();
      newTodDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newTodDo["ok"] = false;
      _toDoList.add(newTodDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //conf da app bar
      appBar: AppBar(
        title: Text(
          "Lista Yago - Compras e Geral",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),

      //conf do body
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Novo Produto",
                        labelStyle: TextStyle(color: Colors.black)),
                  ),
                ),
                RaisedButton(
                  color: Colors.black,
                  child: Text("Adicionar"),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem
              ),
            ),
          )
        ],
      ),
    );
  }

  //funcão que cria os widgets
Widget buildItem(context, index) {
  return Dismissible(
    key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
    background: Container(
      color: Colors.red,
      child: Align(
        alignment: Alignment(-0.9,0.0),
        child: Icon(Icons.delete, color: Colors.white,),
      ),
    ),
    direction: DismissDirection.startToEnd,
    child: CheckboxListTile(
      title: Text(_toDoList[index]["title"]),
      value: _toDoList[index]["ok"],
      secondary: CircleAvatar(
        backgroundColor: Colors.black,
        child: Icon(
            _toDoList[index]["ok"] ? Icons.assignment_turned_in : Icons.assignment_late),
      ),activeColor: Colors.lightGreen,
      onChanged: (c) {
        setState(() {
          _toDoList[index]["ok"] = c;
          _saveData();
        });},
    ),
    onDismissed: (direction){
      setState(() {
        //duplica o item
        _lastRemoved = Map.from(_toDoList[index]);
        _lastRemovedPos = index;
        _toDoList.removeAt(index);

        _saveData();

        final snack = SnackBar(
          content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(label: "Desfazer",
        onPressed: (){
              setState(() {
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
            }),
        duration: Duration(seconds: 2),
        );
        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      });
    },
  );
}

  //criando uma função que retorna o arquivo
  Future<File> _getFile() async {
    //pega o diretorio que pode armazenar os trem
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

//funcao para salvar os dados
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  //funcao para obter os dados
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
//função para atualizar
  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]){
          return 1;
        }else if(!a["ok"] && b["ok"]){
          return -1;
        }else{
          return 0;
        }
        _saveData();
    });
      return null;
    });
  }
}
