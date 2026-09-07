import ntc_templates, os, json

from netmiko import ConnectHandler
from database import save_interface_status


def get_interfaces(ip, username, password):

    os.environ["NET_TEXTFSM"] = os.path.join(
        os.path.dirname(ntc_templates.__file__), "templates"
    )

    device = {
        "device_type": "cisco_ios",
        "host": ip,
        "username": username,
        "password": password,
    }

    with ConnectHandler(**device) as conn:
        # conn.enable()
        result = conn.send_command("show ip int br", use_textfsm=True)
        interfaces_json = json.dumps(result)
        
        save_interface_status(ip, json.loads(interfaces_json))
        
        conn.disconnect()
        print("Done for save interface router:", ip, )

if __name__=='__main__':
    get_interfaces()
