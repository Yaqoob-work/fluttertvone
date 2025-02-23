import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CategoryScreen(),
    );
  }
}

class Channel {
  final String name;
  final String banner;
  final String genres;
  final String videoUrl;

  Channel({
    required this.name,
    required this.banner,
    required this.genres,
    required this.videoUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: json['name'] ?? 'Unknown',
      banner: json['banner'] ?? '',
      genres: json['genres'] ?? 'Unknown',
      videoUrl: json['url'] ?? '',
    );
  }
}

Future<List<Channel>> fetchChannels() async {
  try {
    final response = await http.get(
      Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((channel) => Channel.fromJson(channel)).toList();
    } else {
      print('Failed to load channels. Status code: ${response.statusCode}');
      throw Exception('Failed to load channels');
    }
  } catch (e) {
    print('Error fetching channels: $e');
    throw e;
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String genres;

  VideoPlayerScreen({
    required this.videoUrl,
    required this.genres,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;
  String _errorMessage = '';
  late Future<List<Channel>> futureChannels;
  bool showChannels = false; // Track the state of showing channels
  final FocusNode _fabFocusNode = FocusNode();
  Color _fabColor = Colors.white;

  @override
  void initState() {
    super.initState();
    futureChannels = fetchChannelsByGenres(widget.genres);
    _initializeVideoPlayer();

    _fabFocusNode.addListener(() {
      setState(() {
        _fabColor = _fabFocusNode.hasFocus ? const Color.fromARGB(255, 136, 51, 122): Colors.white;
      });
    });
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isError = true;
          _errorMessage = error.toString();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabFocusNode.dispose();
    super.dispose();
  }

  Future<List<Channel>> fetchChannelsByGenres(String genres) async {
    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
        headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Channel> filteredChannels = data
            .map((channel) => Channel.fromJson(channel))
            .where((channel) => channel.genres == genres)
            .toList();
        return filteredChannels;
      } else {
        print('Failed to load channels. Status code: ${response.statusCode}');
        throw Exception('Failed to load channels');
      }
    } catch (e) {
      print('Error fetching channels: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isError
            ? Text('Error loading video: $_errorMessage')
            : _controller.value.isInitialized
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: showChannels ? 1.0 : 0.0,
                          child: Container(
                            height: 150,
                            color: Colors.black.withOpacity(0.5),
                            child: FutureBuilder<List<Channel>>(
                              future: futureChannels,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(
                                      child: Text('Error: ${snapshot.error}'));
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Center(
                                      child: Text('No channels found'));
                                } else {
                                  List<Channel> channels = snapshot.data!;
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: channels.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: showChannels
                                            ? ChannelItem(
                                                channel: channels[index],
                                                onPressed: () {
                                                  _controller.pause();
                                                },
                                              )
                                            : const SizedBox.shrink(),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
      ),
      floatingActionButton: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: showChannels ? 150 : 16,
            right: 16,
            child: Focus(
              focusNode: _fabFocusNode,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    showChannels = !showChannels; // Toggle the state of showing channels
                  });
                },
                backgroundColor: _fabColor,
                child: Icon(showChannels ? Icons.close : Icons.grid_view),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Channel>> futureChannels;

  @override
  void initState() {
    super.initState();
    futureChannels = fetchChannels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Channel>>(
        future: futureChannels,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No channels found'));
          } else {
            List<Channel> channels = snapshot.data!;
            Map<String, List<Channel>> groupedChannels = {};

            for (var channel in channels) {
              if (groupedChannels[channel.genres] == null) {
                groupedChannels[channel.genres] = [];
              }
              groupedChannels[channel.genres]!.add(channel);
            }

            return ListView(
              children: groupedChannels.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 8.0, left: 16.0, right: 16.0),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ChannelItem(
                              channel: entry.value[index],
                              onPressed: () {
                                // Implement actions on selection if needed
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}

class ChannelItem extends StatefulWidget {
  final Channel channel;
  final VoidCallback onPressed;

  ChannelItem({required this.channel, required this.onPressed});

  @override
  _ChannelItemState createState() => _ChannelItemState();
}

class _ChannelItemState extends State<ChannelItem> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSelect() {
    // Perform actions when the D-pad center button (select button) is pressed
    widget.onPressed();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          videoUrl: widget.channel.videoUrl,
          genres: widget.channel.genres,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        setState(() {
          // Rebuild the widget when focus changes to update border color
        });
      },
      onKey: (node, event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _handleSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _handleSelect, // Handle tap gesture as well
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _focusNode.hasFocus ? 100 : 80,
                height: _focusNode.hasFocus ? 90 : 70,
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        _focusNode.hasFocus ?const Color.fromARGB(255, 136, 51, 122) : Colors.transparent,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(13.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    widget.channel.banner,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: _focusNode.hasFocus ? 100 : 80,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.channel.name,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
