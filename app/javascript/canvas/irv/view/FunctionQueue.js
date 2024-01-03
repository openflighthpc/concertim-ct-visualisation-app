class FunctionQueue {
    constructor() {
        this.queue = [];
    }

    addToQueue(func, args, context) {
        this.queue.push({ func, args, context });
    }

    executeNext() {
       if (this.hasPending()) {
            const { func, args, context } = this.queue.shift();
            func.apply(context, args);
        }
    }

    executeAll() {
        while(this.hasPending()) {
            this.executeNext();
        }
    }

    hasPending() {
        return this.queue.length > 0;
    }
}

export default FunctionQueue;
