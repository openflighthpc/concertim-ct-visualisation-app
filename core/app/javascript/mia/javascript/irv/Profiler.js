// This is a stub file for MA to put in his parser code
//

const Profiler = {
    HIGH        : 40,
    MEDIUM      : 15,
    LOW         : 3,
    UPLOAD      : 'http://milky.homeip.net/web/bits/profiler/store.php?filename=[[filename]]&project=[[project]]&time=[[time]]',
    OUTPUT_ROOT : 'http://milky.homeip.net/web/bits/profiler/projects/',
    CRITICAL    : 10,
    INFO        : 5,
    DEBUG       : 1,
    LOG_LEVEL   : 1,
    TRACE_ONLY  : false,

    log          : [],
    startEvents  : [],
    level        : 1,
    status       : 'idle',
    priority     : null,
    target       : null,
    top          : null,
    bottom       : null,
    totalCPUTime : 0,


    disband: function()
    {
        this.begin  = function(){};
        this.end    = function(){};
        this.trace  = function(){};
        this.output = function(){console.log('Output unavailable, profier has been disbanded');};
    },


    makeCompatible: function()
    {
        tracer = function(log_level, trace)
        {
            if(log_level === undefined || log_level < this.LOG_LEVEL || trace === undefined)
            return;

            if(typeof(trace) === 'string')
            {
                count = 2;
                len   = arguments.length;
                while(count < len)
                {
                    trace = trace.replace(/%s/, arguments[count]);
                    ++count;
                }
            }

            console.log(trace);
        };

        this.begin = tracer;
        this.end   = tracer;
        this.trace = tracer;
        this.output = function(){console.log('Output unavailable, profiler is in compatability mode.');};
    },


    begin: function(log_level, trace)
    {
        if(log_level === undefined || log_level < this.LOG_LEVEL)
        return;

        var start_obj;
        var time   = new Date().getTime();
        var fn     = arguments.callee.caller;
        var caller = this.getCaller(fn);
        var idx    = this.getTimeIdx(fn, caller);
        var log    = { type: 'start',
            caller: caller,
            level: this.level,
            fn: fn,
            timeStamp: time };

        if(trace)
        {
            if(typeof(trace) === 'string')
            {
                count = 2;
                len   = arguments.length;
                while(count < len)
                {
                    trace = trace.replace(/%s/, arguments[count]);
                    ++count;
                }
                log.trace = trace;
            }

            if(!this.TRACE_ONLY)
            console.log(caller + ' ' + trace);
        }

        if(idx === -1)
        {
            start_obj = { fn        : fn,
                caller    : caller,
                timeStamps: [time],
                //idx: this.startEvents.length,
                logs      : [this.log.length] };
            this.startEvents.push(start_obj);
        }
        else
        {
            start_obj = this.startEvents[idx];
            if(start_obj)
            {
                start_obj.timeStamps.push(time);
                start_obj.logs.push(this.log.length);
            }
            else
            console.log("** Failed to  begin for " + caller + " this could be caused by a missing closure. **");
        }

        this.log.push(log);
        ++this.level;
        this.totalCPUTime += new Date().getTime() - time;
    },


    trace: function(log_level, trace)
    {
        if(log_level === undefined || log_level < this.LOG_LEVEL)
        return;

        var time = new Date().getTime();
        if(trace && typeof(trace) === 'string')
        {
            count = 2;
            len   = arguments.length;
            while(count < len)
            {
                trace = trace.replace(/%s/, arguments[count]);
                ++count;
            }
            trace = this.getCaller(arguments.callee.caller) + ' ' + trace;
        }

    this.log.push({ type     : 'trace', 
            level    : this.level,
            timeStamp: time,
            trace    : trace });

        console.log(trace);
        this.totalCPUTime += new Date().getTime() - time;
    },


    end: function(log_level, trace)
    {
        if(log_level === undefined || log_level < this.LOG_LEVEL)
        return;

        var time   = new Date().getTime();
        var fn     = arguments.callee.caller;
        var caller = this.getCaller(fn);
        var idx    = this.getTimeIdx(fn, caller);

        if(idx !== -1)
        {
            var start_obj = this.startEvents[idx];
            var len       = start_obj.timeStamps.length;
            var idx2      = len - 1;
            var run_time  = time - start_obj.timeStamps[idx2];

            --this.level;
            var log = { type     : 'end',
                caller   : caller,
                level    : this.level,
                fn       : fn,
                runTime  : run_time,
                timeStamp: time,
                startIdx : start_obj.logs[idx2] };

        this.log[log.startIdx].endIdx  = this.log.length;
        this.log[log.startIdx].runTime = run_time;

            if(trace)
            {
                if(typeof(trace) === 'string')
                {
                    count = 2;
                    len = arguments.length;
                    while(count < len)
                    {
                        trace = trace.replace(/%s/, arguments[count]);
                        ++count;
                    }
                }
                log.trace = trace;

                if(!this.TRACE_ONLY)
                console.log(caller + ' ' + trace);
            }
            this.log.push(log);


            if(len === 1)
            {
                this.startEvents.splice(idx, 1);
            }
            else
            start_obj.timeStamps.splice(idx2, 1);
            start_obj.logs.splice(idx2, 1);
        }
        else
        console.log("Profiler.dropped: " + caller);

        this.totalCPUTime += new Date() - time;
    },


    getCaller: function(fn)
    {
        var caller = fn.getCall();
        if(caller === undefined)
        {
            try
            {
                this.in_vali_d();
            }
            catch(e)
            {
                caller = e.stack.split('\n')[3].split('at ')[1].split(' (')[0];
                fn.setCall(caller);
            }
        }

        return caller;
    },


    output: function(params)
    {
        if(this.status !== 'idle')
        {
            console.log("Output in progress. Unable to process request at this time.");
            return;
        }

        this.priority = this.MEDIUM;
        this.target   = null;
        this.top      = null;
        this.bottom   = null;

        if(params !== undefined)
        {
            if(params.priority !== undefined)
            this.priority = params.priority;

            if(params.target !== undefined)
            this.target = params.target;

            if(params.top !== undefined)
            this.top = params.top;

            if (params.bottom !== undefined)
            this.bottom = this.log.length - params.bottom;
        }

        this.status = 'busy';
        this.compile();
    },


    compile: function(resume_obj, scope)
    {
        var count, len, out, call_dir, record, source, log;

        var start = new Date().getTime();

        if(scope === undefined)
        scope = this;

        if(resume_obj === undefined)
    {
            out            = {};
            out.callLookup = [];
            out.log        = [];

            if (scope.top !== null && scope.bottom !== null)
        {
                log        = scope.log.slice(scope.top, scope.bottom);
                out.top    = scope.top;
                out.bottom = scope.bottom;
            }
            else if(scope.top !== null)
        {
                log        = scope.log.slice(0, scope.top);
                out.top    = scope.top;
            }
            else if(scope.bottom !== null)
            {
                log        = scope.log.slice(scope.bottom);
                out.bottom = scope.bottom;
            }
            else
            log = scope.log;

            console.log("Commencing compilation");
            count    = 0;
            len      = log.length;
            call_dir = {};
        }
        else
        {
            out      = resume_obj.out;
            count    = resume_obj.count;
            len      = resume_obj.len;
            call_dir = resume_obj.callDir;
            log      = resume_obj.log;
        }

        while(count < len)
        {
            source = log[count];
            record = { type: source.type, timeStamp: source.timeStamp };

            if(source.level !== undefined)
            record.level = source.level;
            if(source.runTime !== undefined)
            record.runTime = source.runTime;
            if(source.endIdx !== undefined)
            record.endIdx = source.endIdx;
            if(source.startIdx !== undefined)
            record.startIdx = source.startIdx;
            if(source.trace !== undefined)
            record.trace = String(source.trace);

            if(source.caller && call_dir[source.caller] === undefined)
        {
                call_dir[source.caller] = out.callLookup.length;
                out.callLookup.push(source.caller);
            }

            record.caller = call_dir[source.caller];
            out.log.push(record);

            ++count;

            if(new Date().getTime() - start >= scope.priority)
        {
                resume_obj = { out: out, count: count, len: len, callDir: call_dir, log: log };
                console.log("Compiled: " + (count / len * 100).toFixed(2) + "%");
                setTimeout(scope.compile, 100, resume_obj, scope);
                return;
            }
        }

        var now     = new Date();
        var ts      = scope.zeroPad(now.getHours(), 2) + '-' +
            scope.zeroPad(now.getMinutes(), 2) + '-' +
            scope.zeroPad(now.getSeconds(), 2) + ' ' +
            scope.zeroPad(now.getDate(), 2) + '-' +
            scope.zeroPad((now.getMonth() + 1), 2) + '-' +
            now.getFullYear();

        console.log('Compiled ' +  out.log.length + ' records.');
        var project  = document.URL.split('//')[1].split('?')[0].split('#')[0];
        project      = project.replace(/[\/\\+\:]/g, '-');
        scope.status = 'idle';
        console.log(out);
        scope.upload(project, ts, JSON.stringify(out));
    },


    upload: function(project, timestamp, log)
    {
        var build_url  = this.UPLOAD;
        build_url      = build_url.replace(/\[\[filename\]\]/g, 'log.json');
        build_url      = build_url.replace(/\[\[project\]\]/g, encodeURIComponent(project));
        build_url      = build_url.replace(/\[\[time\]\]/g, encodeURIComponent(timestamp));

        var output_url = this.OUTPUT_ROOT + encodeURIComponent(project) + '/' + encodeURIComponent(timestamp);
        var scope      = this;

        var req = new XMLHttpRequest();
        req.onreadystatechange = function()
    {
            if(req.readyState === 4)
            {
                if(req.status === 200)
            {
                    if(req.response === undefined)
                {
                        console.log('ERROR: log file too big.');
                        return;
                    }

                    response = eval('(' + req.response + ')');

                    if(response.error)
                    console.log('ERROR: ' + response.message);
                    else
                {
                        console.log('Written ' + response.message + ' bytes.');
                        console.log(output_url);

                        if(scope.target !== null)
                        window.open(output_url, scope.target);
                    }
                }
                else
            {
                    console.log('Failed sending log to server.');
                }
            }
        }
        req.open('POST', build_url, true);
        req.setRequestHeader('Content-type', 'Content-Type: text/plain');
        req.send(log);
    },


    getTimeIdx: function(fn, caller)
{
        // attempt quick lookup
        /*start_obj = this.startsByCaller[caller];
if(start_obj !== undefined && start_obj.fn === fn)
return start_obj.idx;*/

        // an indentically named fn may have overwritten startsByCaller reference so perform slow lookup to be certain
        count = 0;
        len   = this.startEvents.length;
        while(count < len)
    {
            if(this.startEvents[count].fn === fn)
            return count;

            ++count;
        }

        return -1;
    },


    getFnName: function(fn)
{
        if(fn.name)
        return fn.name;

        var name=/\W*function\s+([\w\$]+)\(/.exec(fn);

        if(name && typeof(name) === 'string')
        return name[1];
        else
        return '<anonymous>';
    },


    getObjectClass: function(obj) 
{
        if(obj && obj.constructor && obj.constructor.toString) 
    {
            var arr = obj.constructor.toString().match(/function\s*(\w+)/);

            if (arr && arr.length === 2)
            return arr[1];
        }

        return;
    },


    zeroPad: function(val, len)
{
        val = String(val);
        while(val.length < len)
        val = '0' + val;

        return val;
    }
};


Function.prototype.setCall = function(call1)
{
    this.__call = call1;
};


Function.prototype.getCall = function()
  {
    return this.__call;
};

if(JSON === undefined)
var JSON = {};

JSON.stringify = JSON.stringify || function (obj) 
{
        var t = typeof (obj);
        if (t != "object" || obj === null)
    {
            // simple data type
            if (t == "string")
            obj = '"' + obj + '"';
            return String(obj);
        }
        else 
    {
            // complex data type
            var n, v;
            var json = [];
            var arr = (obj && obj.constructor == Array);

            for (n in obj)
        {
                v = obj[n];
                t = typeof(v);
                if (t == "string")
                v = '"' + v + '"';
                else if (t == "object" && v !== null)
                v = JSON.stringify(v);
                json.push((arr ? "" : '"' + n + '":') + String(v));
            }
            return (arr ? "[" : "{") + String(json) + (arr ? "]" : "}");
        }
    };

document.Profiler = Profiler;
export default Profiler;
