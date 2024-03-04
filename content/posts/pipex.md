+++
title = '쉘의 파이프를 구현하는 과제, Pipex'
date = 2024-03-04T06:27:59Z
tags = ["C_language", "system programming", "42seoul", "pipex"]
+++

## Pipex
  
### 개요
  
Pipex는 쉘의 파이프를 구현하는 과제이다. 실행 파일은 다음과 같은 형식으로 입력을 받아야 한다.  
  
```
./pipex file1 cmd1 cmd2 file2
```
  
그리고 실행 결과는 쉘에서 다음의 명령을 실행한 것과 동일해야 한다.  
  
```
< file1 cmd1 | cmd2 > file2
```
  
예시)
  
```
./pipex infile "ls -l" "wc -l" outfile

// 아래의 줄을 실행한 결과와 같아야 함
< infile ls -l | wc -l > outfile
```
  
이 문제를 해결하기 위해서는 [시스템 콜](https://fjvbn2003.tistory.com/306)을 적극 활용해야 한다. 이 과제를 해결하기 위해서는 [프로세스](https://jerryjerryjerry.tistory.com/178)의 개념을 이해해야 한다.  
  
### execve와 fork
  
리눅스의 모든 것은 파일로 구성되어 있다. 명령어를 실행시키는 것은 어딘가에 저장되어 있는 파일을 실행시키는 것과 동일하므로 따라서 파일을 실행시키는 [execve](https://www.linuxcertif.com/man/3/exec/ko/)를 시용하여 실행시킬 수 있다. 그러나 문제는 execve가 실행되는 즉시 현재 프로세스가 execve가 실행시킨 프로세스로 완전히 대체되어버린다는 것이다.  
  
본 과제에서는 적어도 2개의 커맨드를 실행해야 하고 infile과 outfile의 재지향 또한 처리해야 하므로 execve 뒤에 추가적인 코드가 실행되어야 한다. 이 문제를 해결하기 위해 자식 프로세스를 만드는 [fork](https://www.joinc.co.kr/w/man/2/fork)를 사용한다. 자식 프로세스는 부모 프로세스를 복사하므로 기본적으로는 부모와 동일하게 동작하지만 아래와 같은 방식으로 부모와 별도의 동작을 하게 할 수 있다.  
  
```
fork(&pid); //자식 프로세스의 pid에는 0을, 부모 프로세스의 pid에는 자식 프로세스의 pid(양수)를 배정한다.

if (pid == 0)   //따라서 이 조건문 아래의 코드는
{
    //자식 프로세스에서만 수행된다.
}
```
  
따라서 위와 같은 방식을 활용하여 execve가 자식 프로세스에서만 실행되도록 하여 부모 프로세스에서는 추가적인 코드를 실행할 수 있도록 한다.  
  
### pipe를 활용한 프로세스 간 통신
  
기본적으로 프로세스들은 서로 별도로 실행되기 떄문에 서로 데이터를 주고 받을 수 없다. 그러나 쉘의 파이프는 왼쪽의 명령어의 출력을 오른쪽 명령어의 입력으로 이어주는 기능을 가지고 있다. 즉 첫번째 자식 프로세스의 execve로 실행하는 파일의 출력이 두번째 자식 프로세스의 execve로 실행하는 파일의 입력의 입력으로 이어져야 한다. 이를 해결하기 위해 [pipe](https://www.joinc.co.kr/w/man/2/pipe)를 이용한다. 첫번째 자식 프로세스는 모니터에 출력하는 대신 출력값을 파이프 안에 작성하고, 두번째 자식 프로세스는 키보드 대신 파이프 공간으로부터 입력값을 가져오도록 하는 방식으로 구현할 수 있다. 그런데 어떻게 입력과 출력의 방향을 바꿔야할까?

### dup2를 활용한 재지향(redirection) 구현
  
[dup2](https://www.joinc.co.kr/w/Site/system_programing/File/dup)함수는 2개의 파일 디스크립터를 입력으로 받는데, 두번째 파일 디스크립터가 첫번째 파일디스크립터가 가리키는 대상을 가리키도록 한다. 과제에 필요한, 아래의 재지향을 구현할 수 있다.  
  
1. 첫 번째 명령어(cmd1)의 입력을 파일(file1)로 재지향.
2. 첫 번째 명령어(cmd1)의 출력을 파이프의 쓰기 전용 fd로 재지향.
3. 두 번째 명령어(cmd2)의 입력을 파이프의 읽기 전용 fd로 재지향.
4. 두 번째 명령어(cmd2)의 출력을 파일(file2)로 재지향.
  
앞서 정리한 내용들을 활용하여 최종적으로 구현한 내용은 아래와 같다.
  
```
//..._adv 같은 함수들은 아래와 같이 에러가 발생시 자체적으로 exit하도록 한 함수들이다.
void	fork_adv(pid_t *pid)
{
	*pid = fork();
	if (*pid == -1)
		print_error_exit("error : fork error.\n");
}

//인수로 받는 args는 execve로 넘길 파일 이름과 설정 인자들이다.
void	first_cmd(char **envp, int pipe_fd[2], char ***args)
{
	pid_t	pid;
	int		file_fd;

	file_fd = open(args[0][0], O_RDONLY);
	if (file_fd == -1)
		print_error_exit("error : open failed.\n");
	pipe_adv(pipe_fd);
	fork_adv(&pid);
	if (pid == 0)
	{
		dup2_adv(file_fd, 0);
		dup2_adv(pipe_fd[WRITE], 1);
		close_adv(file_fd);
		close_adv(pipe_fd[READ]);
		close_adv(pipe_fd[WRITE]);
		execve_adv(args[1], envp);
	}
	close_adv(file_fd);
}

void	last_cmd(int argc, char **envp, int pipe_fd[2], char ***args)
{
	pid_t	pid;
	int		file_fd;

	file_fd = open(args[argc - 2][0], O_CREAT | O_TRUNC | O_RDWR, 0644);
	if (file_fd == -1)
		print_error_exit("error : open failed.\n");
	fork_adv(&pid);
	if (pid == 0)
	{
		dup2_adv(pipe_fd[READ], 0);
		dup2_adv(file_fd, 1);
		close_adv(pipe_fd[READ]);
		close_adv(pipe_fd[WRITE]);
		close_adv(file_fd);
		execve_adv(args[argc - 3], envp);
	}
	close_adv(pipe_fd[READ]);
	close_adv(pipe_fd[WRITE]);
	close_adv(file_fd);
}

void	pipex(int argc, char ***args, char **envp)
{
	int	pipe_fd[2];

	first_cmd(envp, pipe_fd, args);
	last_cmd(argc, envp, pipe_fd, args);
	wait_child_end(2);
}

```
  
### 번외. execve가 ls를 usr/bin/ls와 동일하게 인식하게 하기
  
앞선 내용만으로 Pipex 과제의 기본적인 사항들을 성공적으로 구현하는 데에 성공하였다.  
  
```
./pipex infile "usr/bin/ls -l" "usr/bin/wc -l" outfile
```
  
그러나 과제는 아래와 같은 입력도 처리할 수 있어야 한다. 하지만 execve 함수는 현재 디렉도리의 파일이 아닌 이상 절대 경로로만 파일명을 받을 수 있다.
  
```
./pipex infile "ls -l" "wc -l" outfile
```
  
[access](https://www.joinc.co.kr/w/man/2/access)를 이용하여 이를 해결할 수 있다.  
  
```
#include <unistd.h>

int access(const char *pathname, int mode);
```
  
파일의 권한을 체크하기 위한 함수지만, mode를 F_OK로 설정하면 파일의 존재유무를 체크할 수 있다. 따라서 아래와 같은 과정을 통해 문제를 해결한다.  
  
1. main의 envp를 이용하여 PATH를 가져온다.
2. PATH는 :로 여러 개의 경로가 붙어 저장되어 있기 떄문에, 이를 분리한다.
3. 입력 받은 파일명들을 경로와 붙여 새로운 문자열을 만든 다음, 이를 access 함수에 넘겨 존재하는 파일인지 해결한다.
4. 3과정을 PATH의 모든 경로에 대해 적용한다.
  
이를 코드로 구현한 내용은 필자의 [git](https://github.com/Budnarae/42_seoul/tree/main)의 pipex에서 parse_args.c, parse_args_2.c 파일로 확인할 수 있다.