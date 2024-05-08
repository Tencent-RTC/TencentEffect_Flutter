
import 'package:flutter/material.dart';

class ProgressDialog extends Dialog{
  const ProgressDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  const Center(child: CircularProgressIndicator());
  }
}