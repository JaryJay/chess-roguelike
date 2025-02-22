class_name AIThread extends Node

signal move_found(move: Move)

var _initialized: = false

var _is_thinking: = false

var _ai: AbstractAI
var _board: Board
var _mutex: Mutex
var _semaphore: Semaphore
var _thread: Thread
var _exit_thread: = false

func init(ai: AbstractAI) -> void:
	_ai = ai
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_ai_thread_func)
	_initialized = true

func _ai_thread_func() -> void:
	print("AI thread started")
	while true:
		_semaphore.wait()
		_mutex.lock()
		var should_exit: = _exit_thread
		_mutex.unlock()
		
		if should_exit:
			break
		
		_mutex.lock()
		var move: = _ai.get_move(_board)
		_is_thinking = false
		_mutex.unlock()
		move_found.emit.call_deferred(move)

func process_board(board: Board) -> void:
	assert(!_is_thinking, "AI is thinking, cannot process board")
	_mutex.lock()
	_is_thinking = true
	_board = board
	_mutex.unlock()
	_semaphore.post()

func _exit_tree() -> void:
	if !_initialized: return
	
	_mutex.lock()
	_exit_thread = true
	_mutex.unlock()
	_semaphore.post()
	_thread.wait_to_finish()

func is_thinking() -> bool:
	_mutex.lock()
	var thinking: = _is_thinking
	_mutex.unlock()
	return thinking
