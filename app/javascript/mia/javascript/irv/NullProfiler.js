// A NullProfiler to avoid needing to port the real Profiler at this time.

const Profiler = {
    makeCompatible: function() {},
    trace: function() {},
};

export default Profiler;
