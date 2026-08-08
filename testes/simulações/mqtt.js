/**
 * Mock simples para a biblioteca MQTT.js (window.mqtt) para ser injetado em testes E2E ou unitários.
 * Simula a interface básica de conexão, eventos, subscrição e publicação.
 */

class MockMqttClient {
    constructor(brokerUrl) {
        this.brokerUrl = brokerUrl;
        this.connected = true;
        this.subscriptions = new Set();
        this.listeners = {};
        
        // Simula o evento de connect imediato
        setTimeout(() => this._emit('connect'), 10);
    }

    on(event, callback) {
        if (!this.listeners[event]) {
            this.listeners[event] = [];
        }
        this.listeners[event].push(callback);
    }

    _emit(event, ...args) {
        if (this.listeners[event]) {
            this.listeners[event].forEach(cb => cb(...args));
        }
    }

    subscribe(topic) {
        this.subscriptions.add(topic);
        console.log(`[MQTT Mock] Subscribed to ${topic}`);
    }

    publish(topic, message) {
        console.log(`[MQTT Mock] Publishing to ${topic}:`, message);
        
        // Se a mensagem for publicada num tópico em que estamos inscritos,
        // simulamos a entrega de volta como o broker faria para outros clientes
        // (No Angenda, ignoramos mensagens da mesma origem via device name)
        if (this.subscriptions.has(topic)) {
            // Emite o evento "message" com um buffer (simulando a interface do Node.js Buffer usada pelo mqtt.js)
            const mockBuffer = {
                toString: () => typeof message === 'string' ? message : JSON.stringify(message)
            };
            // Delay pequeno pra simular latência de rede
            setTimeout(() => {
                this._emit('message', topic, mockBuffer);
            }, 50);
        }
    }

    end() {
        this.connected = false;
        this.subscriptions.clear();
        console.log(`[MQTT Mock] Connection closed.`);
    }
    
    // Método utilitário para os testes poderem injetar mensagens facilmente como se viessem de fora
    simulateIncomingMessage(topic, payloadObj) {
        if (this.subscriptions.has(topic)) {
            const mockBuffer = {
                toString: () => JSON.stringify(payloadObj)
            };
            this._emit('message', topic, mockBuffer);
        }
    }
}

window.mqtt = {
    connect: function(url, options) {
        console.log(`[MQTT Mock] Connecting to ${url}...`);
        window._mockMqttClient = new MockMqttClient(url);
        return window._mockMqttClient;
    }
};
