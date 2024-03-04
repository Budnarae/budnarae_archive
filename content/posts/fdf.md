+++
title = 'Fdf'
date = 2024-03-04T08:11:23Z
tags = ["C_language", "graphics" ,"42seoul", "fdf"]
+++

## FDF
  
### 개요
  
fdf 과제는 아래와 같이 map 파일을 입력받아 3차원 형태로 출력하도록 하는 과제이다.  
map은 다음과 같이 해석된다.  
  
1. 숫자의 가로 위치 : 3차원 좌표계의 x 값
2. 숫자의 세로 위치 : y 값
3. 숫자의 값 : z 값
  
```
0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
0  0 10 10  0  0 10 10  0  0  0 10 10 10 10 10  0  0  0
0  0 10 10  0  0 10 10  0  0  0  0  0  0  0 10 10  0  0
0  0 10 10  0  0 10 10  0  0  0  0  0  0  0 10 10  0  0
0  0 10 10 10 10 10 10  0  0  0  0 10 10 10 10  0  0  0
0  0  0 10 10 10 10 10  0  0  0 10 10  0  0  0  0  0  0
0  0  0  0  0  0 10 10  0  0  0 10 10  0  0  0  0  0  0
0  0  0  0  0  0 10 10  0  0  0 10 10 10 10 10 10  0  0
0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
```
  
![1](https://i.ytimg.com/vi/uk8_4nJWyE4/maxresdefault.jpg)
  
과제의 세부적인 조건은 다음과 같다.
  
1. [등축투영](https://ko.wikipedia.org/wiki/%EB%93%B1%EC%B6%95_%ED%88%AC%EC%98%81%EB%B2%95)을 사용해야 함.
2. 그래픽 구현에 있어 42 교육과정에서 자체적으로 제작한 [MiniLibx](https://github.com/sejinpark12/MiniLibX_man_kor/blob/main/mlx.md)를 사용할 것.
  
그리고 보너스 점수를 받고 싶다면 다음을 구현해야 한다.
  
1. 등축투영 외의 투영법을 하나 추가하기
2. 확대/축소를 구현하기
3. 이동(translate)을 구현하기
4. 회전(rotate)을 구현하기
5. 이 외에 원하는 추가 기능 하나를 구현하기.
  
필자는 보너스 부분까지 구현하였으며, 아래의 과정을 통해 문제를 해결하였다.  
  
1. 맵의 중앙 부분이 원점에 위치하도록(즉, 10 x 10 크기의 맵의 경우 (5, 5) 위치의 vertex가 원점으로 위치하도록) 이동 행렬을 계산
2. 두 축에 대해 45도씩 회전하는 회전 행렬을 계산.
3. 과재의 보너스 부분을 구현하기 위해, 키보드로 입력이 주어졌을 떄 추가적으로 이루어질 회전, 스케일, 이동 행렬을 계산.
4. 스크린 좌표계로 변환하는 행렬을 계산. 이때, 1과정에서 맵의 중앙 부분이 원점에 위치하도록 했던 것을 되돌린다. 스크린 좌표계에는 음의 영역이 존재하지 않기 때문이다.
5. 1~4에서 계산한 행렬을 행렬곱을 이용하여 압축한다. 행렬을 압축하는 이유는 최적화에 유리하기 때문이다. 만약 100개의 정점에 위의 행렬을 곱한다고 가정할 때, 4 * 100 = 500의 횟수만큼 연산하지만, 행렬을 압축하면 압축 비용(4) + 정점에 적용(100)까지 총 104회의 연산만 소요한다.
6.
  
본 과제의 핵심은 2차원(스크린)에 사물을 입체감이 느껴지게끔 투영하는 것이며, 이를 위해서는 그래픽스 지식이 요구된다.  
그래픽스 이론까지 전부 정리하기엔 내용이 지나치게 방대해지므로, 본문에서는 이를 생략하려 한다. 이 분야에 관심이 있다면 따로 시간을 들여 별도로 공부하는 것을 추천한다. 참고로 필자는 [이득우의 게임수학](https://www.yes24.com/Product/Goods/107025224?pid=123487&cosemkid=go16444756359099763&gad_source=1&gclid=CjwKCAiA_5WvBhBAEiwAZtCU77TGWttww1Z8EDT4GIIOn4JPB8QY7y5i0bpyXUpzsEs-Nj6h2it9sBoC9qgQAvD_BwE)이라는 서적을 통해 그래픽스를 공부했다.
  
### 행렬을 이용한 3차원 공간의 변환
  
개요에서 서술한 내용을 코드로 구현하면 아래와 같다.  
  
```
//map의 중심을 좌표계의 원점(origin)에 위치하도록 하는 이동 행렬
void	init_t_origin(float m[4][4], t_map_size ms)
{
	m[0][0] = 1.0f;
	m[0][1] = 0.0f;
	m[0][2] = 0.0f;
	m[0][3] = -(float)ms.biggest_col_size / 2;
	m[1][0] = 0.0f;
	m[1][1] = 1.0f;
	m[1][2] = 0.0f;
	m[1][3] = -(float)ms.row_size / 2;
	m[2][0] = 0.0f;
	m[2][1] = 0.0f;
	m[2][2] = 1.0f;
	m[2][3] = -(float)ms.biggest_z_size / 2;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//map을 등축투영으로 변환하는 회전 행렬. 이 연산을 통해 데이터가 입체감을 띄게 된다.
void	init_r_isometric(float m[4][4])
{
	float	d;

	d = 45.0f * PI / 180.0f;
	m[0][0] = cos(d);
	m[0][1] = sin(d);
	m[0][2] = 0.0f;
	m[0][3] = 0.0f;
	m[1][0] = -cos(d) * sin(d);
	m[1][1] = cos(d) * cos(d);
	m[1][2] = -sin(d);
	m[1][3] = 0.0f;
	m[2][0] = -(sin(d) * sin(d));
	m[2][1] = cos(d) * sin(d);
	m[2][2] = cos(d);
	m[2][3] = 0.0f;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//보너스 추가 항목. map을 캐비닛 투영으로 변환하는 행렬이다. 축 하나를 기울이는 전단 행렬과 회전 행렬이 압축되어 있다.
void	init_r_cabinet(float m[4][4])
{
	float	d;

	d = PI / 6.0f;
	m[0][0] = 1.0f;
	m[0][1] = -0.5f;
	m[0][2] = 0.0f;
	m[0][3] = 0.0f;
	m[1][0] = 0.0f;
	m[1][1] = cos(d);
	m[1][2] = -sin(d);
	m[1][3] = 0.0f;
	m[2][0] = 0.0f;
	m[2][1] = sin(d);
	m[2][2] = cos(d);
	m[2][3] = 0.0f;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//보너스 추가 항목. 키보드 입력시 맵을 추가로 이동시키는 이동 행렬이다.
void	init_t(float m[4][4], t_control c)
{
	m[0][0] = 1.0f;
	m[0][1] = 0.0f;
	m[0][2] = 0.0f;
	m[0][3] = c.t_x;
	m[1][0] = 0.0f;
	m[1][1] = 1.0f;
	m[1][2] = 0.0f;
	m[1][3] = c.t_y;
	m[2][0] = 0.0f;
	m[2][1] = 0.0f;
	m[2][2] = 1.0f;
	m[2][3] = c.t_z;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//보너스 추가 항목. 키보드 입력시 맵을 추가로 회전시키는 회전 행렬이다.
void	init_r(float m[4][4], t_control c)
{
	float	d;

	d = PI / 180.0f;
	m[0][0] = cos(c.y_roll * d) * cos(c.z_yaw * d)
		+ sin(c.x_pitch * d) * sin(c.y_roll * d) * sin(c.z_yaw);
	m[0][1] = -sin(c.z_yaw * d) * cos(c.x_pitch * d);
	m[0][2] = sin(c.y_roll * d) * cos(c.z_yaw * d)
		+ sin(c.x_pitch * d) * sin(c.z_yaw * d) * cos(c.y_roll * d);
	m[0][3] = 0.0f;
	m[1][0] = sin(c.z_yaw * d) * cos(c.y_roll * d)
		+ sin(c.x_pitch * d) * sin(c.y_roll * d) * cos(c.z_yaw * d);
	m[1][1] = cos(c.x_pitch * d) * cos(c.z_yaw * d);
	m[1][2] = sin(c.y_roll * d) * sin(c.z_yaw * d)
		- sin(c.x_pitch * d) * cos(c.y_roll * d) * cos(c.z_yaw * d);
	m[1][3] = 0.0f;
	m[2][0] = -sin(c.y_roll * d) * cos(c.x_pitch * d);
	m[2][1] = sin(c.x_pitch * d);
	m[2][2] = cos(c.x_pitch * d) * cos(c.y_roll * d);
	m[2][3] = 0.0f;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

보너스 추가 항목. 키보드 입력시 맵을 추가로 확대, 축소시키는 scale 행렬이다.
void	init_s(float m[4][4], t_control control)
{
	m[0][0] = control.scale_factor;
	m[0][1] = 0.0f;
	m[0][2] = 0.0f;
	m[0][3] = 0.0f;
	m[1][0] = 0.0f;
	m[1][1] = control.scale_factor;
	m[1][2] = 0.0f;
	m[1][3] = 0.0f;
	m[2][0] = 0.0f;
	m[2][1] = 0.0f;
	m[2][2] = control.scale_factor;
	m[2][3] = 0.0f;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//처음에 map을 좌표계의 중앙으로 이동시킨 것을 되돌려 스크린 좌표계에 적합하도록 한다.
void	init_t_screen(float m[4][4], t_screen_size screen_size)
{
	m[0][0] = 1.0f;
	m[0][1] = 0.0f;
	m[0][2] = 0.0f;
	m[0][3] = (float)screen_size.col / 2;
	m[1][0] = 0.0f;
	m[1][1] = 1.0f;
	m[1][2] = 0.0f;
	m[1][3] = (float)screen_size.row / 2;
	m[2][0] = 0.0f;
	m[2][1] = 0.0f;
	m[2][2] = 1.0f;
	m[2][3] = 0.0f;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//항등 행렬. 이 행렬에 앞선 행렬들을 모두 곱하여 압축한다.
void	init_merged_matrix(float m[4][4])
{
	m[0][0] = 1.0f;
	m[0][1] = 0.0f;
	m[0][2] = 0.0f;
	m[0][3] = 0.0f;
	m[1][0] = 0.0f;
	m[1][1] = 1.0f;
	m[1][2] = 0.0f;
	m[1][3] = 0.0f;
	m[2][0] = 0.0f;
	m[2][1] = 0.0f;
	m[2][2] = 1.0f;
	m[2][3] = 0.0f;
	m[3][0] = 0.0f;
	m[3][1] = 0.0f;
	m[3][2] = 0.0f;
	m[3][3] = 1.0f;
}

//4x4 행렬곱을 수행하는 함수
void	matrix_multiplication_4x4_4x4(float m1[4][4], float m2[4][4])
{
	int		i;
	int		j;
	float	tmp[4][4];

	i = -1;
	while (++i < 4)
	{
		j = -1;
		while (++j < 4)
			tmp[i][j] = m1[i][0] * m2[0][j] + m1[i][1] * m2[1][j]
				+ m1[i][2] * m2[2][j] + m1[i][3] * m2[3][j];
	}
	i = -1;
	while (++i < 4)
	{
		j = -1;
		while (++j < 4)
			m2[i][j] = tmp[i][j];
	}
}

//행렬과 정점의 곱셈을 수행하는 함수
void	matrix_multiplication_4x4_1x4(float m1[4][4], float m2[4])
{
	int		i;
	float	tmp[4];

	i = -1;
	while (++i < 4)
	{
		tmp[i] = m1[i][0] * m2[0] + m1[i][1] * m2[1]
			+ m1[i][2] * m2[2] + m1[i][3] * m2[3];
	}
	i = -1;
	while (++i < 4)
		m2[i] = tmp[i];
}

void	init_matrix(t_total *total)
{
    //행렬들을 초기화한다.
	init_t_screen(total -> matrixs.t_screen, total -> screen_size);
	init_r_isometric(total -> matrixs.r_isometric);
	init_r_cabinet(total -> matrixs.r_cabinet);
	init_t(total -> matrixs.t, total -> control);
	init_r(total -> matrixs.r, total -> control);
	init_s(total -> matrixs.s, total -> control);
	init_t_origin(total -> matrixs.t_origin, total -> map_size);
	init_merged_matrix(total -> matrixs.merged_matrix);

    //항등행렬에 나머지 행렬들을 곱해 압축한다.

    //map을 좌표계의 중앙으로 옮긴다.
	matrix_multiplication_4x4_4x4(total -> matrixs.t_origin,
		total -> matrixs.merged_matrix);

    //scale, rotation, translation 순으로 곱해야 물체가 찌그러지지 않고 원형이 유지된다. 이를 강체 변환이라고 한다.
	matrix_multiplication_4x4_4x4(total -> matrixs.s,
		total -> matrixs.merged_matrix);
	matrix_multiplication_4x4_4x4(total -> matrixs.r,
		total -> matrixs.merged_matrix);
	matrix_multiplication_4x4_4x4(total -> matrixs.t,
		total -> matrixs.merged_matrix);
    
    //투영행렬을 곱한다.
    //투영이 등축으로 지정되었을 경우
	if (total -> viewpoint == ISO)
		matrix_multiplication_4x4_4x4(total -> matrixs.r_isometric,
			total -> matrixs.merged_matrix);
    //투영이 캐비닛으로 지정되었을 경우
	else if (total -> viewpoint == CAB)
		matrix_multiplication_4x4_4x4(total -> matrixs.r_cabinet,
			total -> matrixs.merged_matrix);
    
    //마지막으로 스크린 좌표계로 변환해주는 행렬을 곱한다.
	matrix_multiplication_4x4_4x4(total -> matrixs.t_screen,
		total -> matrixs.merged_matrix);
}
```
  
### 점과 점을 잇는 선을 그리기 - 브레젠험 알고리즘
  
일련의 과정들을 통해 우리는 3차원 공간의 정점들을 변환하는 데 성공했다. 이제 우리는 이 점들을 이어 선분을 그려야 한다.  
가상의 3차원 공간은 무한하지만 실제 스크린에 담겨 있는 픽셀의 수는 한계가 있기 때문에, 이를 처리하는 과정이 필요하다.  
필자는 [브레젠험 알고리즘](https://blog.naver.com/sorkelf/40151248390)을 사용하여 이를 해결하였다. 실수 연산 없이 정수 연산만을 사용하여 매우 빠르다는 것이 장점으로, 두 점의 픽셀 좌표와 기울기를 사용한 공식을 사용한다.  
  
아래는 이를 코드로 구현한 것이다.
  
```
void	quadrant_4(t_mlx_data mlx_data, t_vertex a, t_vertex b)
{
	int		w;
	int		h;
	int		n;
	int		m;

	w = (int)b.vertex[0] - (int)a.vertex[0];
	h = (int)b.vertex[1] - (int)a.vertex[1];
	n = 0;
	m = 0;
	while ((int)a.vertex[0] - n != (int)b.vertex[0])
	{
		n++;
		if (2 * h * n + 2 * m * w + w >= 0)
			m++;
		if (!((int)a.vertex[0] - n <= 0 || (int)a.vertex[0] - n >= 2560
				|| (int)a.vertex[1] + m <= 0 || (int)a.vertex[1] + m >= 1315))
			my_mlx_pixel_put(&mlx_data.img_data,
				(int)a.vertex[0] - n, (int)a.vertex[1] + m,
				color_lerp(a.color, b.color, -n, w));
	}
}

void	quadrant_3(t_mlx_data mlx_data, t_vertex a, t_vertex b)
{
	int		w;
	int		h;
	int		n;
	int		m;

	w = (int)b.vertex[0] - (int)a.vertex[0];
	h = (int)b.vertex[1] - (int)a.vertex[1];
	n = 0;
	m = 0;
	while ((int)a.vertex[1] + m != (int)b.vertex[1])
	{
		m++;
		if (2 * w * m + 2 * n * h + h <= 0)
			n++;
		if (!((int)a.vertex[0] - n <= 0 || (int)a.vertex[0] - n >= 2560
				|| (int)a.vertex[1] + m <= 0 || (int)a.vertex[1] + m >= 1315))
			my_mlx_pixel_put(&mlx_data.img_data,
				(int)a.vertex[0] - n, (int)a.vertex[1] + m,
				color_lerp(a.color, b.color, m, h));
	}
}

void	quadrant_2(t_mlx_data mlx_data, t_vertex a, t_vertex b)
{
	int		w;
	int		h;
	int		n;
	int		m;

	w = (int)b.vertex[0] - (int)a.vertex[0];
	h = (int)b.vertex[1] - (int)a.vertex[1];
	n = 0;
	m = 0;
	while ((int)a.vertex[1] + m != (int)b.vertex[1])
	{
		m++;
		if (2 * w * m - 2 * n * h - h >= 0)
			n++;
		if (!((int)a.vertex[0] + n <= 0 || (int)a.vertex[0] + n >= 2560
				|| (int)a.vertex[1] + m <= 0 || (int)a.vertex[1] + m >= 1315))
			my_mlx_pixel_put(&mlx_data.img_data,
				(int)a.vertex[0] + n, (int)a.vertex[1] + m,
				color_lerp(a.color, b.color, m, h));
	}
}

void	quadrant_1(t_mlx_data mlx_data, t_vertex a, t_vertex b)
{
	int		w;
	int		h;
	int		n;
	int		m;

	w = (int)b.vertex[0] - (int)a.vertex[0];
	h = (int)b.vertex[1] - (int)a.vertex[1];
	n = 0;
	m = 0;
	while ((int)a.vertex[0] + n != (int)b.vertex[0])
	{
		n++;
		if (2 * h * n - 2 * m * w - w >= 0)
			m++;
		if (!((int)a.vertex[0] + n <= 0 || (int)a.vertex[0] + n >= 2560
				|| (int)a.vertex[1] + m <= 0 || (int)a.vertex[1] + m >= 1315))
			my_mlx_pixel_put(&mlx_data.img_data,
				(int)a.vertex[0] + n, (int)a.vertex[1] + m,
				color_lerp(a.color, b.color, n, w));
	}
}

void	bresenham_2(t_mlx_data mlx_data, t_vertex a, t_vertex b)
{
	float	slope;
	float	*av;
	float	*bv;

	av = a.vertex;
	bv = b.vertex;
	slope = (float)((int)bv[1] - (int)av[1]) / (float)((int)bv[0] - (int)av[0]);
	if (av[0] <= bv[0] && av[1] <= bv[1] && slope < 1.0f && slope >= 0.0f)
		quadrant_1(mlx_data, a, b);
	else if (av[0] <= bv[0] && av[1] <= bv[1] && slope >= 1.0f)
		quadrant_2(mlx_data, a, b);
	else if (av[0] > bv[0] && av[1] <= bv[1] && slope < -1.0f)
		quadrant_3(mlx_data, a, b);
	else if (av[0] > bv[0] && av[1] <= bv[1] && slope >= -1.0f && slope < 0.0f)
		quadrant_4(mlx_data, a, b);
	else if (av[0] > bv[0] && av[1] > bv[1] && slope < 1.0f && slope >= 0.0f)
		quadrant_1(mlx_data, b, a);
	else if (av[0] > bv[0] && av[1] > bv[1] && slope >= 1.0f)
		quadrant_2(mlx_data, b, a);
	else if (av[0] <= bv[0] && av[1] > bv[1] && slope < -1.0f)
		quadrant_3(mlx_data, b, a);
	else if (av[0] <= bv[0] && av[1] > bv[1] && slope >= -1.0f && slope < 0.0f)
		quadrant_4(mlx_data, b, a);
}

void	bresenham(t_mlx_data mlx_data, t_vertex a, t_vertex b)
{
	if ((int)b.vertex[1] == (int)a.vertex[1]
		&& (int)b.vertex[0] > (int)a.vertex[0])
		quadrant_1(mlx_data, a, b);
	else if ((int)b.vertex[1] == (int)a.vertex[1]
		&& (int)b.vertex[0] < (int)a.vertex[0])
		quadrant_1(mlx_data, b, a);
	else if ((int)b.vertex[0] == (int)a.vertex[0]
		&& (int)b.vertex[1] > (int)a.vertex[1])
		quadrant_2(mlx_data, a, b);
	else if ((int)b.vertex[0] == (int)a.vertex[0]
		&& (int)b.vertex[1] < (int)a.vertex[1])
		quadrant_2(mlx_data, b, a);
	else
		bresenham_2(mlx_data, a, b);
}

```