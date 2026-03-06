#!/usr/bin/env python3
"""
生成 Nginx htpasswd 文件的辅助脚本
用法: python3 generate_htpasswd.py <用户名> <密码>
"""
import sys
import crypt
import secrets
import string

def generate_htpasswd_entry(username: str, password: str) -> str:
    """Generate a htpasswd entry using Apache's MD5-based apr1 algorithm."""
    # Generate a random salt (8 characters)
    salt_chars = string.ascii_letters + string.digits
    salt = ''.join(secrets.choice(salt_chars) for _ in range(8))
    
    # Use crypt with apr1 (Apache MD5) algorithm
    # Format: $apr1$salt$hash
    hashed = crypt.crypt(password, f'$apr1${salt}$')
    
    return f'{username}:{hashed}'

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('用法: python3 generate_htpasswd.py <用户名> <密码>')
        print('示例: python3 generate_htpasswd.py Alexander qrz000328')
        sys.exit(1)
    
    username = sys.argv[1]
    password = sys.argv[2]
    
    entry = generate_htpasswd_entry(username, password)
    print(entry)
