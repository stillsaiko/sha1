cd /c/users/saiko/github/sha1
PATH=/mingw32/bin:$PATH
g++ -c sha1.cpp -std=c++17 -lstdc++ -O2 -o sha1.cpp.o
g++ -o sha1.exe -std=c++17 -lstdc++ sha1.cpp.o
rm *.*.o
read -n 1 -s