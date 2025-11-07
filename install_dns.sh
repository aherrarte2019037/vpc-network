#!/bin/bash
sudo apt update
sudo apt install bind9 bind9utils bind9-doc -y
sudo systemctl enable bind9
sudo systemctl start bind9
