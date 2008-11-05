#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CNT 10

char *myreplace(const char *s, const char *old, const char *news) 
{ 
	char *ret, *sr; 
	size_t i, count = 0; 
	size_t newlen = strlen(news); 
	size_t oldlen = strlen(old); 

	if (newlen != oldlen) { 
		for (i = 0; s[i] != '\0'; ) { 
			if (memcmp(&s[i], old, oldlen) == 0) 
				count++, i += oldlen; 
			else 
				i++; 
		} 
	} else 
		i = strlen(s); 

	ret = (char *)malloc(i + 1 + count * (newlen - oldlen)); 
	if (ret == NULL) 
		return NULL; 

	sr = ret; 
	while (*s) { 
		if (memcmp(s, old, oldlen) == 0) { 
			memcpy(sr, news, newlen); 
			sr += newlen; 
			s += oldlen; 
		} else 
			*sr++ = *s++; 
	} 
	*sr = '\0'; 

	return ret; 
}

int main(int argc,char **argv)
{
	if(argc<2){
		printf("Usage: %s [file]\n",argv[0]);
		return(1);
	}
	FILE *in=fopen(argv[1],"rb"),*out;
	if(!in){
		perror("Error opening files");
		return(1);
	}
	char *filesz=(char*)malloc(strlen(argv[1])+3);
	sprintf(filesz,"%s.h",argv[1]);
	out=fopen(filesz,"w");
	if(!out){
		perror("Error opening files");
		return(1);
	}
	free(filesz);
	unsigned long sz,p=0;
	int c,i=CNT;
	fseek(in,0,SEEK_END);
	sz=ftell(in);
	rewind(in);
	
	char* name = myreplace(myreplace(myreplace(argv[1], ".", ""), " ", ""), "bin", "");
	fprintf(out,"#define %s_SZ %ld\n\nconst unsigned char %s[]={",name,sz,name);
	while((c=fgetc(in))!=EOF){
		if(i==CNT){
			fputs("\n\t",out);
			i=0;
		}
		fprintf(out,"0x%02X",c);
		i++;
		p++;
		if(p!=sz) fputc(',',out);
	}
	fputs("\n};\n",out);
	fclose(out);
	fclose(in);
	puts("Done");
	return(0);
}
