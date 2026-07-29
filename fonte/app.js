// IndexedDB integration for Angenda SPA

const DB_NAME = 'angenda_db';
const DB_VERSION = 1;

let db = null;

// Initialize Database
function initDB() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onupgradeneeded = (event) => {
            const dbInstance = event.target.result;
            if (!dbInstance.objectStoreNames.contains('tasks')) {
                dbInstance.createObjectStore('tasks', { keyPath: 'id' });
            }
            if (!dbInstance.objectStoreNames.contains('routines')) {
                dbInstance.createObjectStore('routines', { keyPath: 'id' });
            }
            if (!dbInstance.objectStoreNames.contains('plans')) {
                dbInstance.createObjectStore('plans', { keyPath: 'id' });
            }
        };

        request.onsuccess = (event) => {
            db = event.target.result;
            console.log('IndexedDB initialized successfully.');
            resolve(db);
        };

        request.onerror = (event) => {
            console.error('IndexedDB error:', event.target.error);
            reject(event.target.error);
        };
    });
}

// Generic helper to get all items from a store
function getAllItems(storeName) {
    return new Promise((resolve, reject) => {
        if (!db) {
            return reject(new Error('Database not initialized'));
        }
        const transaction = db.transaction(storeName, 'readonly');
        const store = transaction.objectStore(storeName);
        const request = store.getAll();

        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

// Generic helper to save an item to a store
function saveItem(storeName, item) {
    return new Promise((resolve, reject) => {
        if (!db) {
            return reject(new Error('Database not initialized'));
        }
        const transaction = db.transaction(storeName, 'readwrite');
        const store = transaction.objectStore(storeName);
        const request = store.put(item);

        request.onsuccess = () => resolve();
        request.onerror = () => reject(request.error);
    });
}

// Generic helper to delete an item from a store
function deleteItem(storeName, key) {
    return new Promise((resolve, reject) => {
        if (!db) {
            return reject(new Error('Database not initialized'));
        }
        const transaction = db.transaction(storeName, 'readwrite');
        const store = transaction.objectStore(storeName);
        const request = store.delete(key);

        request.onsuccess = () => resolve();
        request.onerror = () => reject(request.error);
    });
}

// Start Elm App and register Ports
window.addEventListener('DOMContentLoaded', async () => {
    try {
        await initDB();
    } catch (e) {
        console.error('Could not initialize database. Port sync will run with fallback storage.');
    }

    // Initialize Elm application
    // Browser.application needs a flags argument, and returns { ports } if they are declared in Main.elm
    const app = Elm.Main.init({
        node: document.getElementById('elm-app')
    });

    // Handle loadData command
    if (app.ports.loadData) {
        app.ports.loadData.subscribe(async () => {
            try {
                const tasks = await getAllItems('tasks');
                const routines = await getAllItems('routines');
                const plans = await getAllItems('plans');

                console.log('Loaded from DB:', { tasks, routines, plans });

                if (app.ports.dataLoaded) {
                    app.ports.dataLoaded.send({
                        tasks: tasks || [],
                        routines: routines || [],
                        plans: plans || []
                    });
                }
            } catch (err) {
                console.error('Error loading data from IndexedDB:', err);
                // Fallback empty load
                if (app.ports.dataLoaded) {
                    app.ports.dataLoaded.send({ tasks: [], routines: [], plans: [] });
                }
            }
        });
    }

    // Handle saveTask command
    if (app.ports.saveTask) {
        app.ports.saveTask.subscribe(async (task) => {
            try {
                await saveItem('tasks', task);
                console.log('Task saved to IndexedDB:', task.id);
            } catch (err) {
                console.error('Error saving task:', err);
            }
        });
    }

    // Handle deleteTask command
    if (app.ports.deleteTask) {
        app.ports.deleteTask.subscribe(async (taskId) => {
            try {
                await deleteItem('tasks', taskId);
                console.log('Task deleted from IndexedDB:', taskId);
            } catch (err) {
                console.error('Error deleting task:', err);
            }
        });
    }

    // Handle saveRoutine command
    if (app.ports.saveRoutine) {
        app.ports.saveRoutine.subscribe(async (routine) => {
            try {
                await saveItem('routines', routine);
                console.log('Routine saved to IndexedDB:', routine.id);
            } catch (err) {
                console.error('Error saving routine:', err);
            }
        });
    }

    // Handle deleteRoutine command
    if (app.ports.deleteRoutine) {
        app.ports.deleteRoutine.subscribe(async (routineId) => {
            try {
                await deleteItem('routines', routineId);
                console.log('Routine deleted from IndexedDB:', routineId);
            } catch (err) {
                console.error('Error deleting routine:', err);
            }
        });
    }

    // Handle savePlan command
    if (app.ports.savePlan) {
        app.ports.savePlan.subscribe(async (plan) => {
            try {
                await saveItem('plans', plan);
                console.log('Plan saved to IndexedDB:', plan.id);
            } catch (err) {
                console.error('Error saving plan:', err);
            }
        });
    }

    // Handle deletePlan command
    if (app.ports.deletePlan) {
        app.ports.deletePlan.subscribe(async (planId) => {
            try {
                await deleteItem('plans', planId);
                console.log('Plan deleted from IndexedDB:', planId);
            } catch (err) {
                console.error('Error deleting plan:', err);
            }
        });
    }
});
