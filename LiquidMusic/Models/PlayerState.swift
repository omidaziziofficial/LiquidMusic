import Foundation

public struct PlayerState: Equatable {
    public var currentId: Int64
    public var isPlaying: Bool
    public var buffering: Bool
    public var duration: Int64 // ms
    public var position: Int64 // ms
    public var shuffle: Bool
    public var repeatMode: RepeatMode
    public var queue: [Int64]
    public var index: Int
    public var hasNext: Bool
    public var hasPrevious: Bool
    
    public init(
        currentId: Int64 = -1,
        isPlaying: Bool = false,
        buffering: Bool = false,
        duration: Int64 = 0,
        position: Int64 = 0,
        shuffle: Bool = false,
        repeatMode: RepeatMode = .off,
        queue: [Int64] = [],
        index: Int = -1,
        hasNext: Bool = false,
        hasPrevious: Bool = false
    ) {
        self.currentId = currentId
        self.isPlaying = isPlaying
        self.buffering = buffering
        self.duration = duration
        self.position = position
        self.shuffle = shuffle
        self.repeatMode = repeatMode
        self.queue = queue
        self.index = index
        self.hasNext = hasNext
        self.hasPrevious = hasPrevious
    }
}
