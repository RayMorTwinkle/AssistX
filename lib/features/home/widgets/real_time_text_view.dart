import 'package:flutter/material.dart';

/// 实时文本显示组件
/// 支持自动换行、平滑滚动和文本分块管理
class RealTimeTextView extends StatelessWidget {
  const RealTimeTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return _RealTimeTextViewStateful(key: key);
  }
}

class _RealTimeTextViewStateful extends StatefulWidget {
  const _RealTimeTextViewStateful({super.key});

  @override
  _RealTimeTextViewState createState() => _RealTimeTextViewState();
}

class _RealTimeTextViewState extends State<_RealTimeTextViewStateful> {
  final ScrollController _scrollController = ScrollController();
  final TextChunkManager _textChunkManager = TextChunkManager();
  final List<String> _textChunks = [];
  final bool _isRecording = false;

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      padding: EdgeInsets.all(16.0),
      constraints: const BoxConstraints(minHeight: 300),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和录音状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '实时转写结果',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    )
                  ),
                  _isRecording ? _buildRecordingIndicator(theme) : Container(),
                ],
              ),
              
              // 文本显示区域
              _buildTextDisplay(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.0),
        Text(
          '正在录音...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          )
        ),
      ],
    );
  }

  Widget _buildTextDisplay(ThemeData theme) {
    // 如果没有文本，显示占位符
    if (_textChunks.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Text(
          '开始录音后，文本将在此处显示',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 显示分块的文本
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _textChunks.map((chunk) {
        final bool isCompleteSentence = _textChunkManager.isCompleteSentence(chunk);
        
        return Container(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            chunk,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isCompleteSentence ? FontWeight.normal : FontWeight.w500,
              color: isCompleteSentence
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.primary,
            ),
            textAlign: TextAlign.justify,
            softWrap: true,
          ),
        );
      }).toList(),
    );
  }
}

/// 文本分块管理器，用于优化大文本的内存使用和渲染性能
class TextChunkManager {
  final int maxChunkSize = 500; // 每个块的最大字符数
  final List<String> _chunks = [];
  
  /// 添加文本并根据句号进行分块
  List<String> addText(String text) {
    if (text.isEmpty) return _chunks;
    
    // 获取最后一个块（如果存在）
    String lastChunk = _chunks.isNotEmpty ? _chunks.last : '';
    
    // 合并最后一个块和新文本
    String mergedText = lastChunk + text;
    
    // 检查是否包含句号
    int lastPeriodIndex = mergedText.lastIndexOf('.');
    
    if (lastPeriodIndex != -1 && lastPeriodIndex > 0) {
      // 如果有句号，分割成已完成和未完成两部分
      String completedPart = mergedText.substring(0, lastPeriodIndex + 1); // 包含句号
      String incompletePart = mergedText.substring(lastPeriodIndex + 1);
      
      // 移除最后一个块（我们将替换它）
      if (_chunks.isNotEmpty) {
        _chunks.removeLast();
      }
      
      // 将完成的部分分割成适当大小的块
      _splitAndAddChunks(completedPart);
      
      // 添加未完成的部分作为新的最后一个块（如果非空）
      if (incompletePart.isNotEmpty) {
        _chunks.add(incompletePart);
      }
    } else if (mergedText.length > maxChunkSize) {
      // 如果没有句号但文本太长，按长度分块
      if (_chunks.isNotEmpty) {
        _chunks.removeLast();
      }
      _splitAndAddChunks(mergedText);
    } else {
      // 否则，更新最后一个块
      if (_chunks.isNotEmpty) {
        _chunks.last = mergedText;
      } else {
        _chunks.add(mergedText);
      }
    }
    
    return List.from(_chunks);
  }
  
  /// 分割文本并添加到块列表
  void _splitAndAddChunks(String text) {
    int start = 0;
    while (start < text.length) {
      int end = start + maxChunkSize;
      if (end < text.length) {
        // 尝试在空格处分割，避免切断单词
        int spaceIndex = text.substring(start, end).lastIndexOf(' ');
        if (spaceIndex != -1) {
          end = start + spaceIndex + 1;
        }
      } else {
        end = text.length;
      }
      _chunks.add(text.substring(start, end));
      start = end;
    }
  }
  
  /// 检查文本块是否是完整的句子（以句号结尾）
  bool isCompleteSentence(String chunk) {
    return chunk.isNotEmpty && chunk.endsWith('.');
  }
  
  /// 清空所有文本块
  void clear() {
    _chunks.clear();
  }
  
  /// 获取所有文本块
  List<String> getChunks() {
    return List.from(_chunks);
  }
  
  /// 获取文本总长度
  int getTextLength() {
    return _chunks.fold(0, (length, chunk) => length + chunk.length);
  }
}