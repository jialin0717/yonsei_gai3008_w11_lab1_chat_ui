import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const ChatLabApp());
}

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

// 채팅 메시지 모델
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final List<ChatMessage> _messages = [];

  late final AnimationController _dotsController;

  bool _sending = false;
  bool _typing = false;
  String? _error;
  String? _lastMessage;

  // 테스트용: 첫 번째 재시도에서는 오류를 복구한다.
  bool _retryRecovery = false;

  bool get _reduceMotion {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  Duration get _insertDuration {
    return _reduceMotion ? Duration.zero : const Duration(milliseconds: 250);
  }

  @override
  void initState() {
    super.initState();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  // 메시지 추가 및 삽입 애니메이션
  void _addMessage(ChatMessage message) {
    final index = _messages.length;

    setState(() {
      _messages.add(message);
    });

    _listKey.currentState?.insertItem(index, duration: _insertDuration);

    _scrollToBottom();
  }

  // reverse:true이므로 0이 최신 메시지 위치
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      if (_reduceMotion) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 전송 버튼 또는 Enter 키
  Future<void> _send() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) return;

    _controller.clear();

    _lastMessage = text;
    _retryRecovery = false;

    _addMessage(ChatMessage(text: text, isUser: true));

    await _requestReply(text);
  }

  // AI 응답 요청 (11주차 로컬 MOCK)
  Future<void> _requestReply(String text) async {
    if (_sending) return;

    setState(() {
      _sending = true;
      _typing = true;
      _error = null;
    });

    if (!_reduceMotion) {
      _dotsController.repeat();
    }

    try {
      // 실제 API 대신 2초 지연을 시뮬레이션한다.
      await Future.delayed(const Duration(seconds: 2));

      // 오류 테스트용 입력
      final command = text.toLowerCase().trim();

      if (!_retryRecovery) {
        if (command == 'error' || command == '500') {
          throw const MockChatException(500);
        }
        if (command == '401') {
          throw const MockChatException(401);
        }
        if (command == '429') {
          throw const MockChatException(429);
        }
        if (command == 'timeout') {
          throw TimeoutException('Mock timeout');
        }
      }

      if (!mounted) return;

      final answer = _mockAnswer(text);

      setState(() {
        _typing = false;
      });

      _dotsController.stop();

      _addMessage(ChatMessage(text: answer, isUser: false));
    } on MockChatException catch (e) {
      if (!mounted) return;

      final message = switch (e.status) {
        401 => '키/권한을 확인해 주세요',
        429 => '잠시 후 다시 시도해 주세요',
        500 => '응답을 받지 못했습니다',
        _ => '네트워크를 확인해 주세요',
      };

      setState(() {
        _error = message;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _error = '네트워크를 확인해 주세요';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = '응답을 받지 못했습니다';
      });
    } finally {
      if (mounted) {
        _dotsController.stop();

        setState(() {
          _sending = false;
          _typing = false;
        });
      }
    }
  }

  // 오류 후 마지막 사용자 메시지 재시도
  Future<void> _retry() async {
    if (_sending || _lastMessage == null) return;

    // 로컬 테스트에서는 재시도 성공을 시뮬레이션한다.
    _retryRecovery = true;

    await _requestReply(_lastMessage!);
  }

  // 로컬 테스트용 AI 답변
  String _mockAnswer(String text) {
    final command = text.toLowerCase().trim();

    if (command == 'error' ||
        command == '500' ||
        command == '401' ||
        command == '429' ||
        command == 'timeout') {
      return '다시 시도에 성공했습니다. '
          '정상적으로 응답을 받았습니다.';
    }

    if (text.contains('안녕')) {
      return '안녕하세요! 무엇을 도와드릴까요?';
    }

    if (text.contains('Flutter')) {
      return 'Flutter는 하나의 코드베이스로 '
          '여러 플랫폼의 앱을 개발할 수 있는 프레임워크입니다.';
    }

    return '메시지를 받았습니다: $text';
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduce = _reduceMotion;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('AI Chat — 실습 1'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            // 채팅 목록 및 빈 상태
            Expanded(
              child: Stack(
                children: [
                  AnimatedList(
                    key: _listKey,
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    initialItemCount: _messages.length,
                    itemBuilder: (context, index, animation) {
                      final message = _messages[_messages.length - 1 - index];

                      return SizeTransition(
                        sizeFactor: reduce
                            ? const AlwaysStoppedAnimation<double>(1)
                            : animation,
                        alignment: Alignment.centerLeft,
                        child: _Bubble(message: message),
                      );
                    },
                  ),

                  if (_messages.isEmpty)
                    const Center(
                      child: Text(
                        '무엇이든 물어보세요',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),

            // AI 응답 대기: 점 3개
            if (_typing)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: reduce
                        ? const Text('응답을 기다리는 중...')
                        : TypingDots(controller: _dotsController),
                  ),
                ),
              ),

            // 오류 메시지 및 재시도
            if (_error != null)
              AnimatedSwitcher(
                duration: reduce
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: Padding(
                  key: ValueKey(_error),
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: _sending ? null : _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 메시지 입력창
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 사용자 / AI 말풍선
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: message.isUser
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 15,
            color: message.isUser
                ? colors.onPrimaryContainer
                : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

// 200ms 간격으로 움직이는 타이핑 점
class TypingDots extends StatelessWidget {
  const TypingDots({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final active = (controller.value * 3).floor() % 3;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedOpacity(
                opacity: index == active ? 1.0 : 0.25,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// 로컬 오류 시뮬레이션
class MockChatException implements Exception {
  const MockChatException(this.status);

  final int status;
}
