import tkinter as tk
import serial
import serial.tools.list_ports
import threading

class SerialDataReader:
    def __init__(self, baudrate=9600):
        self.baudrate = baudrate
        self.serial_connection = None
        self.previous_value = None

    def connect_to_first_device(self):
        available_ports = self.find_serial_ports()
        for port in available_ports:
            if self.connect(port):
                return True, port
        return False, None

    def connect(self, port):
        try:
            self.serial_connection = serial.Serial(port, self.baudrate)
            return True
        except serial.SerialException as e:
            return False

    def read_data(self):
        if self.serial_connection and self.serial_connection.is_open:
            return self.serial_connection.read(1)  # Read one byte
        else:
            return b'No connection'

    def write_data(self, data):
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.write(data)

    def close(self):
        if self.serial_connection and self.serial_connection.is_open:
            self.serial_connection.close()

    def find_serial_ports(self):
        available_ports = []
        ports = serial.tools.list_ports.comports()
        for port, desc, hwid in sorted(ports):
            available_ports.append(port)
        return available_ports

class SerialDataReaderGUI:
    def __init__(self, master):
        self.master = master
        master.title("USB-вольтметр. Медведева Е. ИУ4-62Б. ООО \" Амплифер \"")
     
        master.geometry("500x300")

        self.label1 = tk.Label(master, text="Значение, В:", bg="#FFFFFF", fg="#000000", font=("Roboto", 12))
        self.label1.pack()

        self.data_label1 = tk.Label(master, text="", bg="#FFFFFF", fg="#191970", font=("Arial", 16))
        self.data_label1.pack()

        self.label2 = tk.Label(master, text="Диапазон №:", bg="#FFFFFF", fg="#000000", font=("Arial", 12))
        self.label2.pack()

        self.data_label2 = tk.Label(master, text="", bg="#FFFFFF", fg="#191970", font=("Arial", 14))
        self.data_label2.pack()

        self.connect_button = tk.Button(master, text="Включить", command=self.connect, bg="#B0C4DE", fg="#000000", font=("Arial", 12))
        self.connect_button.pack(pady=10)

        self.disconnect_button = tk.Button(master, text="Выключить", command=self.disconnect, bg="#B0C4DE", fg="#000000", font=("Arial", 12))
        self.disconnect_button.pack(pady=10)

        self.log_text = tk.Text(master, height=6, width=40, bg="#FFFFFF", fg="#000000", font=("Arial", 12))
        self.log_text.pack(pady=10)

        master.config(bg="#FFFFFF")

        self.serial_reader = SerialDataReader()
        self.reading_thread = None
        self.stop_reading_flag = threading.Event()

    def log_message(self, message):
        self.log_text.insert(tk.END, message + '\n')
        if float(self.log_text.index('end-1c')) > 6.0:
            self.log_text.delete('1.0', '2.0')
        self.log_text.see(tk.END)

    def connect(self):
        connected, port = self.serial_reader.connect_to_first_device()
        if connected:
            self.connect_button.config(state=tk.DISABLED)
            self.disconnect_button.config(state=tk.NORMAL)
            self.start_reading_thread()
            self.log_message("Устройство успешно подключено к порту {}.".format(port))
        else:
            self.log_message("Не удалось подключить устройство.")

    def disconnect(self):
        self.stop_reading_flag.set()
        self.serial_reader.close()
        self.connect_button.config(state=tk.NORMAL)
        self.disconnect_button.config(state=tk.DISABLED)
        self.log_message("Соединение с устройством закрыто.")

    def start_reading_thread(self):
        if not self.reading_thread or not self.reading_thread.is_alive():
            self.stop_reading_flag.clear()
            self.reading_thread = threading.Thread(target=self.read_data_from_port)
            self.reading_thread.daemon = True
            self.reading_thread.start()

    def read_data_from_port(self):
        while not self.stop_reading_flag.is_set():
            try:
                data = self.serial_reader.read_data()
                if data:  # Проверяем, есть ли данные
                    if data == b'\xAA':
                        data = self.serial_reader.read_data()
                        if data == b'\xBB':
                            data = self.serial_reader.read_data()
                            if data == b'\xCC':
                                data = b'\xAA\xBB\xCC'
                                self.serial_reader.write_data(data)
                    else:
                        number = None  # Инициализируем number здесь
                        try:
                            number = int.from_bytes(data, byteorder='big', signed=False)
                            if self.serial_reader.previous_value is not None:
                                if number == 1:
                                    self.master.after(100, self.update_data_display, self.serial_reader.previous_value / 100, number)
                                elif number == 2:
                                    self.master.after(100, self.update_data_display, self.serial_reader.previous_value / 100, number)
                                elif number == 3:
                                    self.master.after(100, self.update_data_display, self.serial_reader.previous_value / 10, number)
                        except ValueError:
                            pass

                        if number is not None:  # Проверяем, что number был установлен перед его использованием
                            self.serial_reader.previous_value = number
            except serial.SerialException:
                self.log_message("Устройство отключено.")
                self.disconnect()  # Вызываем метод отключения, чтобы корректно завершить чтение данных
                break

    def update_data_display(self, previous_value, range_value):
        self.data_label1.config(text=str(previous_value))
        self.data_label2.config(text=str(range_value))

if __name__ == "__main__":
    root = tk.Tk()
    app = SerialDataReaderGUI(root)
    root.mainloop()
