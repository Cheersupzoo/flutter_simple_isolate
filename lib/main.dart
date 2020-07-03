import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Colors.white,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          backgroundColor: Colors.grey[900],
          scaffoldBackgroundColor: Colors.grey[900],
          accentColor: Colors.white,
          textTheme: Theme.of(context)
              .textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white)),
      home: MyHomePage(title: 'Flutter Simple Isolate'),
    );
  }
}

int fibonacci(int n) {
  /// fibonacci recursive
  assert(n >= 1);
  if (n == 1)
    return 0;
  else if (n == 2) return 1;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int fiboResult = 0;
  Future<int> fibonacciWithCompute(int n) async {
    /// calculate fibonacci on Isolate with compute
    return await compute(fibonacci, n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Transform.scale(scale: 2.5, child: CircularProgressIndicator()),
              SizedBox(height: 72.0),
              Text(
                'Fibonacci 40th',
              ),
              SizedBox(height: 8.0),
              Text(
                '$fiboResult',
                style: Theme.of(context).textTheme.headline4,
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                      onPressed: () async {
                        fiboResult = await fibonacciWithCompute(40);
                        setState(() {});
                      },
                      child: Text("Fibo non-blocking")),
                  SizedBox(width: 16),
                  RaisedButton(
                      onPressed: () {
                        setState(() {
                          fiboResult = fibonacci(40);
                        });
                      },
                      child: Text("Fibo blocking")),
                ],
              ),
              RaisedButton(
                  onPressed: () {
                    setState(() {
                      fiboResult = 0;
                    });
                  },
                  child: Text("Reset"))
            ],
          ),
        ));
  }

  Future<int> fibonacciWithIsolate(int n) async {
    /// calculate fibonacci on Isolate
    /// this part is still on EventLoop
    ReceivePort receivePort = ReceivePort();
    // Completer for create a workflow waiting for Isolate to finish
    final Completer<int> result = Completer<int>();
    // spawn Isolate
    var isolate = await Isolate.spawn(
        fibonacciForIsolate, new FiboPort(n, receivePort.sendPort));
    receivePort.listen((fiboResult) {
      /// recieve fiboResult from Isolate
      result.complete(fiboResult as int);
    });

    /// wait till result is complete
    await result.future;

    /// close receive port and kill the isolate
    receivePort.close();
    isolate.kill();
    return result.future;
  }
}

// For fibonacciWithIsolate
class FiboPort {
  int n;
  SendPort sendPort;

  FiboPort(this.n, this.sendPort);
}

// For fibonacciWithIsolate
void fibonacciForIsolate(FiboPort fiboPort) {
  /// On Isolate thread
  var fiboResult = fibonacci(fiboPort.n);

  /// after get the result, send it back to EventLoop
  fiboPort.sendPort.send(fiboResult);
}
