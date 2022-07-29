#include <iostream>
#include <fstream>
#include <string>
using namespace std;
std::ifstream fin;
std::ofstream fout;
string source_file_name;
string target_file_name;
const string default_file_name = "a.data";
void bin_to_hex_text();
void print_err_info(const string & err);

int main(int argc, char * argv[])
{
	if(argc == 1)
		return 0;
	if(string(argv[1]) == "-o")
	{
		if(argc > 4)
			print_err_info("arguments is more than ecpected!");
		else if(argc < 4)
			print_err_info("arguments is less than expected!");
		else
		{
			source_file_name = argv[3];
			target_file_name = argv[2];
		}
	}
	else
	{
		if(argc > 2)
			print_err_info("arguments is more than ecpected!");
		else if(argc < 2)
			print_err_info("arguments is less than expected!");
		else
		{
			source_file_name = argv[1];
			target_file_name = default_file_name;
		}
	}
	bin_to_hex_text();
	return 0;
}

void print_err_info(const string & err)
{
	cout << '\n'<< err << "\nThere just two types of commands are available:\n\n    command -o target_file_name source_file_name\n";
	cout << "    command source_file_name  \n\nin the second case, the target file name is " << default_file_name << " which is default\n";
	cout << "please check out and retype.\n";
	exit(-1);
}

void bin_to_hex_text()
{
	fin.open(source_file_name);
	if(!fin)
	{
		cout << "failed to open source file " << source_file_name << endl;;
		exit(-1);
	}
	fout.open(target_file_name);
	if(!fout)
	{
		cout << "failed to create target file " << source_file_name << endl;
		exit(-1);
	}
	fout << hex;    // 十六进制形式输出
	char ch;
	int count = 0;
	while(fin.get(ch))
	{
		count ++;
		int value = static_cast<unsigned char>(ch);
		// cout << value << endl;
		if(value < 0x10)
			fout << '0';
		fout << value;
		if(count % 4 == 0) // 4个字节，32位，一条指令
			fout << '\n';
	}
	fin.close();
	fout.close();
}
