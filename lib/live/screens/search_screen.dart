import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> searchResults = [];
  bool isLoading = false;
  TextEditingController _searchController = TextEditingController();
  int selectedIndex = -1;
  double iconSize = 30.0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      iconSize = _focusNode.hasFocus ? 20.0 : 15.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: MediaQuery.of(context).size.width * 0.1,
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            // prefix: IconButton(
            //   icon: Icon(Icons.search, color: Colors.white, size: iconSize),
            //   onPressed: () {
            //     _performSearch(_searchController.text);
            //   },
            // ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                  color: Color.fromARGB(255, 136, 51, 122), width: 4.0),
            ),
            labelText: 'Search By Channel Name',
          ),
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.search,
          textAlignVertical:
              TextAlignVertical.center, // Vertical center alignment
          onChanged: (value) {
            _performSearch(value);
          },
          onSubmitted: (value) {
            _performSearch(value);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : searchResults.isEmpty
                  ? const Expanded(
                      child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'No results found'
                          
                          ,
                            style: TextStyle(color: Color.fromARGB(255, 59, 54, 54)),
                          ),
                          
                        ],
                      )),
                    )
                  : Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _onItemTap(index);
                            },
                            child: _buildGridViewItem(index),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildGridViewItem(int index) {
    double bannerWidth = selectedIndex == index ? 110 : 90;
    double bannerHeight = selectedIndex == index ? 90 : 70;

    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.select) {
          _onItemTap(index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (hasFocus) {
        setState(() {
          selectedIndex = hasFocus ? index : -1;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedIndex == index
                        ? const Color.fromARGB(255, 136, 51, 122)
                        : Colors.transparent,
                    width: 5.0,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    searchResults[index]['banner'] ?? '',
                    width: bannerWidth,
                    height: bannerHeight,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Container(
                width: bannerWidth,
                child: Text(
                  searchResults[index]['name'] ?? 'Unknown',
                  style: TextStyle(
                    color:
                        selectedIndex == index ? Colors.yellow : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performSearch(String searchTerm) async {
    setState(() {
      isLoading = true;
      searchResults.clear();
    });

    try {
      final response = await http.get(
        Uri.parse('https://mobifreetv.com/android/getFeaturedLiveTV'),
        headers: {
          'x-api-key': 'vLQTuPZUxktl5mVW',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          if (searchTerm.isEmpty) {
            searchResults.clear();
          } else {
            searchResults = responseData
                .where((channel) =>
                    channel['name'] != null &&
                    channel['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchTerm.toLowerCase()))
                .toList();

            // Initialize isFocused to false for each channel
            searchResults.forEach((channel) {
              if (channel['isFocused'] == null) {
                channel['isFocused'] = false;
              }
            });
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onItemTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(
          videoUrl: searchResults[index]['url'] ?? '',
          videoTitle: searchResults[index]['name'] ?? 'Unknown',
          channelList: searchResults,
          onFabFocusChanged: _handleFabFocusChanged,
        ),
      ),
    );
  }

  void _handleFabFocusChanged(bool hasFocus) {
    // Handle FAB focus change if needed
  }
}






class VideoScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final List<dynamic> channelList;
  final Function(bool) onFabFocusChanged; // Callback to notify FAB focus change

  VideoScreen({
    required this.videoUrl,
    required this.videoTitle,
    required this.channelList,
    required this.onFabFocusChanged,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool isGridVisible = false;
  int selectedIndex = -1;
  bool isFullScreen = false;
  double volume = 0.5;
  bool isVolumeControlVisible = false; // Add this flag
  Timer? _hideVolumeControlTimer; // Timer to hide the volume control
  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    _controller.setVolume(volume);

    // Initialize focus nodes for each channel item
    focusNodes =
        List.generate(widget.channelList.length, (index) => FocusNode());

    // Initialize isFocused to false for each channel
    widget.channelList.forEach((channel) {
      if (channel['isFocused'] == null) {
        channel['isFocused'] = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideVolumeControlTimer?.cancel(); // Cancel the timer if it's active
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void toggleGridVisibility() {
    setState(() {
      isGridVisible = !isGridVisible;
    });
  }

  void toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
    });
  }

  void _onItemFocus(int index, bool hasFocus) {
    setState(() {
      widget.channelList[index]['isFocused'] =
          hasFocus; // Update channel focus state
      if (hasFocus) {
        selectedIndex = index;
      } else if (selectedIndex == index) {
        selectedIndex = -1;
      }
    });
  }

  void _onItemTap(int index) {
    setState(() {
      selectedIndex = index;
    });

    String selectedUrl = widget.channelList[index]['url'] ?? '';
    // String selectedTitle = widget.channelList[index]['name'] ?? 'Unknown';
    _controller.pause();
    _controller = VideoPlayerController.network(selectedUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {}); // Trigger rebuild after initialization
      _controller.play();
      _controller.setVolume(volume);
    });
  }

  void _showVolumeControl() {
    setState(() {
      isVolumeControlVisible = true;
    });

    _hideVolumeControlTimer?.cancel(); // Cancel any existing timer

    // Start a new timer to hide the volume control after a delay
    _hideVolumeControlTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        isVolumeControlVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    // aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        // Progress bar
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: _controller.value.position.inSeconds /
                                _controller.value.duration.inSeconds,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          if (!isFullScreen)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isVolumeControlVisible)
                    Row(
                      children: [
                        const Icon(Icons.volume_up),
                        Expanded(
                          child: Slider(
                            value: volume,
                            min: 0,
                            max: 1,
                            onChanged: (value) {
                              setState(() {
                                volume = value;
                                _controller.setVolume(volume);
                                _showVolumeControl(); // Show the volume control
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: isGridVisible ? 160 : 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: toggleGridVisibility,
              child: Icon(isGridVisible ? Icons.close : Icons.grid_view),
            ),
          ),
          if (isGridVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 150,
                color: Colors.black87,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.channelList.length,
                  itemBuilder: (context, index) {
                    double bannerWidth = selectedIndex == index ? 100 : 80;
                    double bannerHeight = selectedIndex == index ? 90 : 60;
                    return GestureDetector(
                      onTap: () => _onItemTap(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50.0),
                        child: Focus(
                          focusNode: focusNodes[index],
                          onKey: (FocusNode node, RawKeyEvent event) {
                            if (event is RawKeyDownEvent &&
                                (event.logicalKey ==
                                        LogicalKeyboardKey.select ||
                                    event.logicalKey ==
                                        LogicalKeyboardKey.enter)) {
                              _onItemTap(index);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          onFocusChange: (hasFocus) {
                            _onItemFocus(index, hasFocus);
                          },
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: widget.channelList[index]
                                                  ['isFocused']
                                              ? const Color.fromARGB(255, 136, 51, 122)
                                              : Colors.transparent,
                                          width: 5.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          widget.channelList[index]['banner'] ??
                                              '',
                                          fit: widget.channelList[index]
                                                  ['isFocused']
                                              ? BoxFit.cover
                                              : BoxFit.contain,
                                          width: bannerWidth,
                                          height: bannerHeight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Container(
                                    width: bannerWidth,
                                    child: Text(
                                      widget.channelList[index]['name'] ??
                                          'Unknown',
                                      style: TextStyle(
                                        color: widget.channelList[index]
                                                ['isFocused']
                                            ? const Color.fromARGB(255, 136, 51, 122)
                                            : Colors.white.withOpacity(0.6),
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SearchScreen(),
    theme: ThemeData.dark(),
  ));
}
