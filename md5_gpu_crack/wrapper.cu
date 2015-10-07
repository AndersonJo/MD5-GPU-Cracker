#include <python2.7/Python.h>
#include "main.cu"

//static PyObject * md5_gpu_crack_wrapper(PyObject *self, PyObject *args, PyObject *keywds) {
//	printf("md5_gpu_crack_wrapper\n");
//	static char* kwlist[] = { NULL };
//	int digit = 4;
//	const char* string =
//			"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~\0";
//
//	if (!PyArg_ParseTupleAndKeywords(args, keywds, "s|is", kwlist, &digit, &string)) {
//		return NULL;
//	}
//
//	printf("%s\n", kwlist[0]);
//	printf("%s\n", string);
//	Py_INCREF(Py_None);
//	return Py_None;
//
//	// run the actual function
//	// result = hello(input);
//
//	// build the resulting string into a Python object.
//	//  ret = PyString_FromString(result);
//	// free(result);
//}

static PyObject * md5_gpu_crack_wrapper(PyObject * self, PyObject * args, PyObject * keywds) {
	const char *kwlist[] = {"hash", "digit", "string", "block", "thread"};
	char *hash;
	char *string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~\0";
	int digit = 4;
	int block = 128;
	int thread = 1024;

	if (!PyArg_ParseTupleAndKeywords(args, keywds, "si|siii", kwlist, &hash, &digit, &string, &block, &thread)) {
		return NULL;
	}
	printf("Hello md5_gpu_crack_wrapper\n");

	char* result = anderson_main(hash, digit, string, block, thread, 1);
	printf("result: %s\n", result);
	PyObject* answer = Py_BuildValue("s", result);
	printf("HAHA 01\n");

	Py_INCREF(answer);
	printf("HAHA 02\n");

	return answer;
}

static PyMethodDef md5_gpu_crack_methods[] = { { "crack", (PyCFunction) md5_gpu_crack_wrapper, METH_VARARGS
		| METH_KEYWORDS, "MD5 GPU Cracking" }, { NULL, NULL, 0, NULL } };

PyMODINIT_FUNC initcracker(void) {
	PyObject *m;

	m = Py_InitModule("cracker", md5_gpu_crack_methods);
	if (m == NULL)
		return;

//	SpamError = PyErr_NewException("spam.error", NULL, NULL);
//	Py_INCREF(SpamError);
//	PyModule_AddObject(m, "error", SpamError);
}
