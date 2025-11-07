import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EnrollmentForm extends StatefulWidget {
  // 可选参数：允许传入课程标题和描述
  final String courseTitle;
  final String courseDescription;

  const EnrollmentForm({
    super.key,
    this.courseTitle = 'Flutter 入门培训（15堂课）',
    this.courseDescription = '本课程覆盖Flutter基础到Web/App开发，共15堂课，帮助零基础学员快速上手。',
  });

  @override
  State<EnrollmentForm> createState() => _EnrollmentFormState();
}

class _EnrollmentFormState extends State<EnrollmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String _message = '';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _message = '';
      });

      // 模拟提交到后端（替换为你的API，例如Firebase）
      try {
        final response = await http.post(
          Uri.parse('https://your-api-endpoint.com/enroll'),  // 替换为实际API
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'course': widget.courseTitle,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            _message = '报名成功！我们会尽快联系您。';
          });
          _clearForm();
        } else {
          setState(() {
            _message = '提交失败，请重试。';
          });
        }
      } catch (e) {
        setState(() {
          _message = '网络错误，请检查连接。';
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 课程介绍卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.courseTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.courseDescription),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('课程时长：15堂课 | 费用：300USD'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 报名表单标题
            Text(
              '填写报名信息',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '邮箱 *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return '请输入有效邮箱';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '电话（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue[600],
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('立即报名', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 16),

            // 反馈消息
            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('成功') ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.contains('成功') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message.contains('成功') ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}