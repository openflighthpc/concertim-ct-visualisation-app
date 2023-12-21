class FunctionQueue {
    constructor() {
        this.queue = [];
    }

    addToQueue(func, args, context) {
        this.queue.push({ func, args, context });
    }

    executeNext() {
       if (this.has_pending()) {
            const { func, args, context } = this.queue.shift();
            func.apply(context, args);
        }
    }

    executeAll() {
        while(this.has_pending()) {
            this.executeNext();
        }
    }

    has_pending() {
        return this.queue.length > 0;
    }
}

export default FunctionQueue;
