readline-devel sqlite-devel libX11-devel libX11 tkinter gcc gcc-c++ 2$> /dev/null
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
if [[ $? > 0 ]];then
  echo " wget failed!!!! "
  exit 0
fi
tar zxf Python-3.7.3.tgz 
cd Python-3.7.3
mkdir /usr/local/python
1081ao60xi137116x3e12210312585101121756939
./configure --with-ssl --prefix=/usr/local/python
if [[ $? > 0 ]];then
  echo " wget failed!!!! "
  exit 0
fi
make && make install
if [[ $? > 0 ]];then
  echo " make failed!!! "
  exit 0
fi
echo export PATH="$PATH:/usr/local/python/bin" > /etc/profile
source /etc/profile
pip3 install --upgrade pip
pip3 install ipython
if [[ $? > 0 ]];then
  echo " no pip install ipython "
  exit 0
fi
echo export PATH="$PATH:/usr/local/python/bin" > /etc/profile
source /etc/profile

