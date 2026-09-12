import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: CustomScrollView(
        slivers: [
          AnimatedBuilder(
            animation: AlwaysStoppedAnimation(0.0),
            builder: (context, child) {
              return SliverAppBar(
                title: Text('Test'),
              );
            },
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Text('Item 1'),
            ]),
          )
        ],
      ),
    ),
  ));
}
