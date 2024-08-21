import os
import base64

def encode_file_to_base64(input_file_path, output_file_path):
    with open(input_file_path, 'rb') as input_file:
        file_content = input_file.read()
    
    encoded_content = base64.b64encode(file_content)
    
    with open(output_file_path, 'wb') as output_file:
        output_file.write(encoded_content)

def decode_file_from_base64(input_file_path, output_file_path):
    with open(input_file_path, 'rb') as input_file:
        encoded_content = input_file.read()
    
    decoded_content = base64.b64decode(encoded_content)
    
    with open(output_file_path, 'wb') as output_file:
        output_file.write(decoded_content)

if __name__ == "__main__":
    action = input("请输入 'encode' 编码文件或 'decode' 解码Base64文件: ").strip().lower()
    
    if action == "encode":
        input_file_name = input("请输入要编码的文件名 (包括扩展名): ").strip()
        current_dir = os.getcwd()
        input_file_path = os.path.join(current_dir, input_file_name)
        output_file_name = "encoded_" + os.path.basename(input_file_name)
        output_file_path = os.path.join(current_dir, output_file_name)
        encode_file_to_base64(input_file_path, output_file_path)
        print(f"文件已编码并保存到 {output_file_path}")
    
    elif action == "decode":
        input_file_name = input("请输入要解码的Base64文件名 (包括扩展名): ").strip()
        current_dir = os.getcwd()
        input_file_path = os.path.join(current_dir, input_file_name)
        
        # 自动识别并保留原始文件扩展名
        original_file_base_name = input_file_name.split('.')[0].replace("encoded_", "", 1) 
        output_file_name = original_file_base_name + "." + input_file_name.split('.')[-1]
        output_file_path = os.path.join(current_dir, output_file_name)
        
        decode_file_from_base64(input_file_path, output_file_path)
        print(f"文件已解码并保存到 {output_file_path}")
    
    else:
        print("无效操作，请输入 'encode' 或 'decode'")
